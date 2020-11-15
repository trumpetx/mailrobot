MR = LibStub("AceAddon-3.0"):NewAddon("MailRobot", "AceConsole-3.0", "AceEvent-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale("MailRobot")
local AceGUI = LibStub("AceGUI-3.0")
local LibJSON = LibStub("LibJSON-1.0")

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
    list = {
      type = "execute",
      name = L["List Item Values"],
      desc = L["List all item values to the chat console"],
      func = "ListItems",
      guiHidden = true,
    },
  },
}

local defaults = {
  profile = {
    debug = false,
    itemValues = {},
    enabled = true,
  }
}

function MR:OnInitialize()
  self.db = LibStub("AceDB-3.0"):New("MailRobotDB", defaults, true)
  self.frame = nil
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

function MR:ValidateRemoveItem(a, args)
  local item, amount = self:GetArgs(args, 1)
  if item == nil then
    return L["usage: /mr remove [item]"]
  end
  local itemName, _ = GetItemInfo(item)
  if itemName == nil then
    return L["usage: /mr remove [item]"]
  end
  return true
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
  else
    LibStub("AceConfigCmd-3.0"):HandleCommand(L["mr"], "MailRobot", input)
  end
end

function MR:MAIL_CLOSED(event, ...)
  self:Debug(event)
  if self.frame ~= nil then
    AceGUI:Release(self.frame)
    self.frame = nil
  end
end

function MR:MAIL_INBOX_UPDATE(event, ...)
  self:Debug(event)
  if self.frame ~= nil or not self.db.profile.enabled then
    self:Debug("Window already open or window disabled")
    return
  end
  local numItems, totalItems = GetInboxNumItems()
  self:Debug("numItems=" .. numItems .. ", totalItems=" .. totalItems)
  if self.frame ~= nil then
    AceGUI:Release(self.frame)
    self.frame = nil
  end
  self.frame = AceGUI:Create("Frame")
  self.frame:SetWidth(300)
  self.frame:SetTitle(L["Mail Robot"])
  self.frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget); self.frame = nil end)
  self.frame:SetLayout("Fill")
  local scrollcontainer = AceGUI:Create("SimpleGroup")
  scrollcontainer:SetFullWidth(true)
  scrollcontainer:SetFullHeight(true)
  scrollcontainer:SetLayout("Fill")
  self.frame:AddChild(scrollcontainer)
  local scroll = AceGUI:Create("ScrollFrame")
  scroll:SetLayout("Flow")
  scrollcontainer:AddChild(scroll)
  local noValueItems = {}
  local buttonGroups = {}
  for i=1, numItems do
    local packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, hasItem, wasRead, wasReturned, _ = GetInboxHeaderInfo(i);
    if hasItem and sender and not wasReturned then
      for j=1, ATTACHMENTS_MAX_RECEIVE do
        local link = GetInboxItemLink(i, j)
        if link then
          local name, itemId, texture, count, quality, canUse = GetInboxItem(i, j)
          local amountPerItem = self.db.profile.itemValues[name]
          if amountPerItem == nil then
            noValueItems[name] = link;
          else
            self:Debug(name .. " has a value of " .. amountPerItem)
            local amount = amountPerItem * count
            local epgpSender = EPGP:GetFullCharacterName(sender)
            if EPGP:CanIncEPBy(name, amount) then
              local buttonGroup = buttonGroups[sender]
              if buttonGroup == nil then
                buttonGroup = AceGUI:Create("InlineGroup")
                buttonGroup:SetTitle(sender)
                buttonGroups[sender] = buttonGroup
                scroll:AddChild(buttonGroup)
              end
              local button = AceGUI:Create("Button")
              button:SetText(L["ApplyButton"](amount, count, name))
              button:SetFullWidth(true)
              button:SetCallback("OnClick", function()
                if EPGP:IncEPBy(epgpSender, name, amount, false, false) then
                  self:Debug("Increased " .. sender .. "'s EP by " .. amount .. " for recipt of " .. count .. " " .. link)
                  button:SetDisabled(true)
                else
                  self:Debug("Unable to increase " .. sender .. "'s EP by " .. amount .. " for recipt of " .. count .. " " .. link)
                end
              end)
              buttonGroup:AddChild(button)
            else
              self:Debug("Not able to apply EP (edit officer notes?)")
            end
          end
        end
      end
    end
  end

  --
  -- Add in inputs for No EP value
  --
  for item,link in pairs(noValueItems) do
    local editBox = AceGUI:Create("EditBox")
    editBox:SetText("")
    editBox:SetLabel(link)
    editBox:DisableButton(false)
    editBox:SetCallback("OnTextChanged", function(_, _, txt)
      if txt == nil then return end
      local match = string.match(txt, '[0-9]*')
      if match ~= txt then
        editBox:SetText(match)
      end
    end)
    editBox:SetCallback("OnEnterPressed", function(_, _, amount)
      if MR:_AddItem(item, link, amount) then
        editBox:SetDisabled(true)
      end
    end)
    scroll:AddChild(editBox)
  end
end

function MR:Debug(msg)
  if self.db.profile.debug then
    if msg == nil then
      msg = "nil"
    end
    self:Print("|cFFFFFF00" .. msg .. "|r")
  end
end

function MR:DebugTable(tbl, header)
  self:Debug(header)
  for i=1,#tbl do
    self:Debug(i .. LibJSON.Serialize(tbl[i]))
  end
end
