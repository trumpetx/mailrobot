MR = LibStub("AceAddon-3.0"):NewAddon("MailRobot", "AceConsole-3.0", "AceEvent-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale("MailRobot")
local AceGUI = LibStub("AceGUI-3.0")
local LibJSON = LibStub("LibJSON-1.0")

StaticPopupDialogs["MR_BAGS_FULL"] = {
  text = L["Your bags are full"],
  button1 = L["Ok"],
  timeout = 0,
  whileDead = false,
  hideOnEscape = true,
  preferredIndex = 3,
}

local options = {
  name = L["Mail Robot"],
  handler = MR,
  type = "group",
  args = {
    enabled = {
      type = "toggle",
      name = L["Enabled"],
      desc = L["Toggles the Mail Robot popup"],
      get = "GetEnabled",
      set = "SetEnabled",
    },
    debug = {
      type = "toggle",
      name = L["Debug"],
      desc = L["Toggles debug mode"],
      get = "GetDebugMode",
      set = "SetDebugMode",
    },
    maxPoints = {
      type = "input",
      name = L["Maximum Points"],
      desc = L["Set Maximum Points (until reset)"],
      get = "GetMaxPoints",
      set = "SetMaxPoints",
      validate = "ValidateMaxPoints"
    },
    add = {
      type = "input",
      name = L["Add a item"],
      desc = L["Adds a item value to the database"],
      get = false,
      set = "AddItem",
      validate = "ValidateAddItem",
      guiHidden = true,
    },
    remove = {
      type = "input",
      name = L["Remove an item"],
      desc = L["Remove a item & value from the database"],
      get = false,
      set = "RemoveItem",
      validate = "ValidateRemoveItem",
      guiHidden = true,
    },
    clear = {
      type = "input",
      name = L["Clear character's total points"],
      desc = L["Resets a character's total points to zero"],
      get = false,
      set = "ClearTotal",
      validate = "ValidateClearTotal",
      guiHidden = true,
    },
    clearAll = {
      type = "execute",
      name = L["Clear all character's total points"],
      desc = L["Resets all character's total points to zero"],
      func = "ClearAllTotal",
      guiHidden = true,
    },
    list = {
      type = "execute",
      name = L["List Item Values"],
      desc = L["List all item values to the chat console"],
      func = "ListItems",
      guiHidden = true,
    },
    removeAll = {
      type = "execute",
      name = L["Reset Item Values"],
      desc = L["Removes all values assigned to items"],
      func = "RemoveAll",
    }
  },
}

local defaults = {
  profile = {
    debug = false,
    itemValues = {},
    enabled = true,
    playerPoints = {},
    maxPoints = 0,
  }
}

function MR:OnInitialize()
  self.db = LibStub("AceDB-3.0"):New("MailRobotDB", defaults, true)
  self.frame = nil
end

function MR:GetMaxPoints(info)
  return self.db.profile.maxPoints
end

function MR:SetMaxPoints(info, value)
  self.db.profile.maxPoints = value
  self:Debug(L["Maximum Points"] .. ": " .. self.db.profile.maxPoints)
end

function MR:ValidateMaxPoints(a, args)
  local amount = self:GetArgs(args, 1)
  if tonumber(amount) == nil then
    return L["usage: /mr maxPoints ##"]
  end
  return true
end

function MR:GetDebugMode(info)
  return self.db.profile.debug
end

function MR:SetDebugMode(info, value)
  self.db.profile.debug = value
  self:Print(L["Debug mode "] .. L[value and "enabled" or "disabled"])
end

function MR:GetEnabled(info)
  return self.db.profile.enabled
end

function MR:SetEnabled(info, value)
  self.db.profile.enabled = value
  self:Print(L["MailRobot window "] .. L[value and "enabled" or "disabled"])
end

function MR:ValidateClearTotal(a, args)
  local character = self:GetArgs(args, 1)
  if character == nil then
    return L["usage: /mr clearTotal [character]"]
  end
  return true
end

function MR:ClearTotal(a, args)
  local character = self:GetArgs(args, 1)
  self.db.profile.playerPoints[character] = 0
  if self.frame ~= nil then
    self:MAIL_INBOX_UPDATE("MAIL_INBOX_UPDATE")
  end
end

function MR:ClearAllTotal(a, args)
  self.db.profile.playerPoints = {}
  if self.frame ~= nil then
    self:MAIL_INBOX_UPDATE("MAIL_INBOX_UPDATE")
  end
  self:Debug("Player points reset, max points = " .. self:GetMaxPoints())
end

function MR:ValidateRemoveItem(a, args)
  local item = self:GetArgs(args, 1)
  if item == nil then
    return L["usage: /mr remove [item]"]
  end
  local itemName, _ = GetItemInfo(item)
  if itemName == nil then
    return L["usage: /mr remove [item]"]
  end
  return true
end

function MR:RemoveAll()
  self:CloseWindow()
  self.db.profile.itemValues = {}
  self:Print(L["Item values reset!"])
end

function MR:RemoveItem(a, args)
  local item = self:GetArgs(args, 1)
  self:AddItem(a, item .. " -1")
end

function MR:ValidateAddItem(a, args)
  local item, amount = self:GetArgs(args, 2)
  if item == nil then
    return L["usage: /mr add [item] ##"]
  end
  local itemName, _ = GetItemInfo(item)
  if (itemName == nil) or (tonumber(amount) == nil) then
    return L["usage: /mr add [item] ##"]
  end
  return true
end

function MR:_AddItem(itemName, itemLink, amount)
  if tonumber(amount) >= 0 then
    self.db.profile.itemValues[itemName] = amount
    self:Print("Added " .. itemLink .. " to the database (" .. amount .. ")")
    return true
  else
    self.db.profile.itemValues[itemName] = nil
    self:Print("Removed " .. itemLink .. " from the database")
    return false
  end
end

function MR:AddItem(a, args)
  local item, amount = self:GetArgs(args, 2)
  local itemName, itemLink, _ = GetItemInfo(item)
  if itemName == nil then return end
  self:_AddItem(itemName, itemLink, amount)
end

function MR:OnEnable()
  self:Print(L["AddonEnabled"](GetAddOnMetadata("MailRobot", "Version"), GetAddOnMetadata("MailRobot", "Author")))
  self.firstOpen = true
  self.isShown = false
  self.canIncEp = false
  if self.db.profile.playerPoints == nil then self.db.profile.playerPoints = {} end
  LibStub("AceConfig-3.0"):RegisterOptionsTable("MailRobot", options)
  self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("MailRobot", L["Mail Robot"])
  self:RegisterChatCommand(L["mr"], "ChatCommand")
  self:RegisterChatCommand(L["mailrobot"], "ChatCommand")
  self:RegisterEvent("MAIL_INBOX_UPDATE")
  self:RegisterEvent("MAIL_CLOSED")
  self:Debug("Debug Enabled")
end

function MR:ListItems()
  for item,points in pairs(self.db.profile.itemValues) do
    local itemName, itemLink, _ = GetItemInfo(item)
    self:Print((itemLink or item) .. " = " .. points)
  end
end

function MR:ChatCommand(input)
  if input == nil then
    input = ""
  end
  input = input:trim()
  if input == "" or input == "config" or input == "settings" then
    -- Blizzard bug - doesn't open to correct frame the first time
    if self.firstOpen then
      self.firstOpen = false
      InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
    end
    InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
  elseif input == "help" then
    LibStub("AceConfigCmd-3.0"):HandleCommand(L["mr"], "MailRobot", "")
  else
    LibStub("AceConfigCmd-3.0"):HandleCommand(L["mr"], "MailRobot", input)
  end
end

function MR:CloseWindow()
  if self.frame ~= nil then
    AceGUI:Release(self.frame)
    self.frame = nil
  end
end

function MR:MAIL_CLOSED(event, ...)
  self:Debug(event)
  self:CloseWindow()
end

function MR:MAIL_INBOX_UPDATE(event, ...)
  self:Debug(event)
  if not self.db.profile.enabled then
    self:Debug("Window disabled")
    return
  end

  if not self.canIncEp then
    -- Once you can edit, you can always edit (not technically true, but EPGP will return false whlie reloading sometimes)
    self.canIncEp = EPGP:CanIncEPBy("test", 1)
  end

  if not self.canIncEp then
    self:Debug("Unable to edit EPGP, supressing window popup")
    return
  end

  if self.frame == nil then
    self:CreateWindow()
  else
    local numItems, totalItems = GetInboxNumItems()
    if numItems == 0 then
      self:CloseWindow()
    else
      self:UpdateWindow(numItems, totalItems)
    end
  end
end

function MR:CreateWindow()
  local numItems, totalItems = GetInboxNumItems()
  if numItems == 0 then
    self:Debug("No mail items, not creating window")
    return
  end

  self.frame = AceGUI:Create("Frame")
  self.frame:SetWidth(350)
  self.frame:SetTitle(L["Mail Robot"])
  self.frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget); self.frame = nil end)
  self.frame:SetLayout("Fill")
  local scrollcontainer = AceGUI:Create("SimpleGroup")
  scrollcontainer:SetFullWidth(true)
  scrollcontainer:SetFullHeight(true)
  scrollcontainer:SetLayout("Fill")
  self.frame:AddChild(scrollcontainer)
  local scrollFrame = AceGUI:Create("ScrollFrame")
  scrollFrame:SetLayout("Flow")
  scrollcontainer:AddChild(scrollFrame)
  self.frame.scrollFrame = scrollFrame
  self:UpdateWindow(numItems, totalItems)
end

function MR:UpdateWindow(numItems, totalItems)
  local scrollFrame = self.frame.scrollFrame
  scrollFrame:ReleaseChildren()
  -- Add "always" button(s)
  local button = AceGUI:Create("Button")
  button:SetText(L["Reset All Totals"])
  button:SetFullWidth(true)
  button:SetHeight(16)
  button:SetCallback("OnClick", function() self:ClearAllTotal(nil, "") end)
  scrollFrame:AddChild(button)

  local scale = .5
  local imageSize = scale * 36
  local iconSize = scale * 48

  local noValueItems = {}
  local buttonGroups = {}
  --
  -- Cycle through the mail and create buttons (grouped by sender name) where the applicable EP would be > 0
  --
  self:Debug("numItems=" .. numItems .. ", totalItems=" .. totalItems)
  for mailboxIndex=1, numItems do
    local packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, hasItem, wasRead, wasReturned, _ = GetInboxHeaderInfo(mailboxIndex)
    local isAuction = GetInboxInvoiceInfo(mailboxIndex) ~= nil
    if hasItem and sender and not wasReturned and not isAuction then
      for mailIndex=1, ATTACHMENTS_MAX_RECEIVE do
        local link = GetInboxItemLink(mailboxIndex, mailIndex)
        if link then
          local name, itemId, texture, count, quality, canUse = GetInboxItem(mailboxIndex, mailIndex)
          local amountPerItem = self.db.profile.itemValues[name]
          if amountPerItem == nil then
            noValueItems[name] = link;
          else
            self:Debug(name .. " has a value of " .. amountPerItem)
            local amount = round(amountPerItem * count)
            local epgpSender = EPGP:GetFullCharacterName(sender)
            if amount > 0 then
              local maxPoints = tonumber(self:GetMaxPoints()) or 0
              local difference = 0
              local playerPoints = self.db.profile.playerPoints[sender]
              if playerPoints == nil then playerPoints = 0 end
              if(maxPoints > 0 and (playerPoints + amount) >= maxPoints) then
                local originalAmount = amount
                amount = round(maxPoints - playerPoints)
                difference = round(originalAmount - amount)
              end
              local buttonGroup = buttonGroups[sender]
              if buttonGroup == nil then
                buttonGroup = AceGUI:Create("SimpleGroup")
                local playerPoints = self.db.profile.playerPoints[sender];
                if playerPoints == nil then playerPoints = 0 end

                local resetButton = AceGUI:Create("Button")
                resetButton:SetText(L["Reset Total"])
                resetButton:SetWidth(95)
                resetButton:SetCallback("OnClick", function() self:ClearTotal(nil, sender) end)

                local name = LibStub("AceGUI-3.0"):Create("Label")
                name:SetText(sender .. "  [ " ..  playerPoints .." ]")
                fontName, fontHeight, fontFlags = name.label:GetFont()
                name:SetHeight(fontHeight + 2)
                name:SetWidth(170)
                name:SetFont(fontName, fontHeight + 2, fontFlags)

                local titleBar = AceGUI:Create("SimpleGroup")
                titleBar:SetFullWidth(true)
                titleBar:SetHeight(fontHeight + 2)
                titleBar:AddChild(name)
                titleBar:AddChild(resetButton)
                titleBar:SetLayout("Flow")

                buttonGroup:AddChild(titleBar)
                buttonGroups[sender] = buttonGroup
              end
              local button = AceGUI:Create("Button")
              button:SetText(L["ApplyButton"](amount, difference, count, name))
              button:SetWidth(275)
              button:SetCallback("OnClick", function()
                if maxPoints > 0 and amount == 0 then
                  self:Debug("Unable to increase " .. sender .. "'s EP by " .. difference .. ".  They are at max EP.")
                elseif self:OpenBagSlot(itemId) and EPGP:IncEPBy(epgpSender, name, amount, false, false) then
                  self.db.profile.playerPoints[sender] = playerPoints + amount
                  self:Debug("Increased " .. sender .. "'s EP by " .. amount .. " T(" .. self.db.profile.playerPoints[sender] .. ")" .. " for receipt of " .. count .. " " .. link)
                  button:SetDisabled(true)
                  TakeInboxItem(mailboxIndex, mailIndex)
                else
                  self:Debug("Unable to increase " .. sender .. "'s EP by " .. amount .. " for receipt of " .. count .. " " .. link)
                end
              end)
              local noPointsButton = AceGUI:Create("Icon")
              noPointsButton:SetImage("interface\\icons\\inv_gauntlets_04")
              noPointsButton:SetFullWidth(false)
              noPointsButton:SetImageSize(imageSize, imageSize)
              noPointsButton:SetHeight(iconSize)
              noPointsButton:SetWidth(iconSize)
              noPointsButton:SetCallback("OnClick", function()
                if self:OpenBagSlot(itemId) then
                  noPointsButton:SetDisabled(true)
                  TakeInboxItem(mailboxIndex, mailIndex)
                else
                  self:Debug("Unable to take " .. link .. " from " .. sender)
                end
              end)
              row = AceGUI:Create("SimpleGroup")
              row:SetLayout("Flow")
              row:AddChild(button)
              row:AddChild(noPointsButton)
              buttonGroup:AddChild(row)
            else
              self:Debug("Value of " .. count .. "x" .. name .. " is 0")
            end
          end
        end
      end
    end
  end

  --
  -- Add the (alpha sorted) inputs
  --
  for _, k in ipairs(sortedKeys(buttonGroups)) do
    scrollFrame:AddChild(buttonGroups[k])
  end

  --
  -- Add in inputs for No EP value
  --
  if next(noValueItems) ~= nil then
    local unknownValues = {}
    for item,link in pairs(noValueItems) do
      local editBox = AceGUI:Create("EditBox")
      editBox:SetText("")
      editBox:SetLabel(link)
      editBox:DisableButton(false)
      editBox:SetCallback("OnTextChanged", function(_, _, txt)
        if txt == nil then return end
        local match = string.match(txt, '[0-9.]*')
        if match ~= txt then
          editBox:SetText(match)
        end
      end)
      editBox:SetCallback("OnEnterPressed", function(_, _, amount)
        if MR:_AddItem(item, link, amount) then
          editBox:SetDisabled(true)
          self:UpdateWindow(numItems, totalItems)
        end
      end)
      unknownValues[item] = editBox
    end

    local inputGroup = AceGUI:Create("InlineGroup")
    inputGroup:SetTitle(L["Unknown Item Values"])
    for _, k in ipairs(sortedKeys(unknownValues)) do
      inputGroup:AddChild(unknownValues[k])
    end
    scrollFrame:AddChild(inputGroup)
  end
end

function MR:OpenBagSlot(item)
  local itemFamily = GetItemFamily(item)
  for bagID=0, NUM_BAG_SLOTS do
    self:Debug("itemType: " .. itemFamily)
    numberOfFreeSlots, bagItemFamily = GetContainerNumFreeSlots(bagID);
    if numberOfFreeSlots > 0 then
      self:Debug("Checking bag: " .. bagID .. ", type: " .. bagItemFamily .. ", freeSlots: " .. numberOfFreeSlots)
      if (bagItemFamily == 0 or bagItemFamily == itemFamily) then
        return true
      end
    else
      self:Debug("Bag: " .. bagID .. " does not exist or is full")
    end
  end
  StaticPopup_Show("MR_BAGS_FULL")
  return false
end

function MR:Debug(msg)
  if self.db.profile.debug then
    if msg == nil then
      msg = "nil"
    end
    self:Print("|cFFFFFF00" .. msg .. "|r")
  end
end
