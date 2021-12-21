local L =  LibStub("AceLocale-3.0"):NewLocale("MailRobot", "enUS", true)
if not L then return end

L["Mail Robot"] = true
L["Debug"] = true
L["enabled"] = true
L["Debug mode "] = true
L["disabled"] = true
L["Toggles debug mode"] = true
L["mr"] = true
L["mailrobot"] = true
L["AddonEnabled"] = function(X,Y)
	return 'version ' .. X .. ' by |cFF00FF00' .. Y .. '|r loaded'
end
L["ApplyButton"] = function(amount, difference, count, name)
	return amount .. (difference > 0 and "(" .. difference .. ")" or "") .. " EP for " .. count .. " " .. name
end
L["Add a item"] = true
L["Adds a item value to the database"] = true
L["usage: /mr add [item] ##"] = true
L["List Item Values"] = true
L["List all item values to the chat console"] = true
L["Remove an item"] = true
L["Remove a item & value from the database"] = true
L["Enabled"] = true
L["Toggles the Mail Robot popup"] = true
L["MailRobot window "] = true
L["Unknown Item Values"] = true
L["Reset Item Values"] = true
L["Removes all values assigned to items"] = true
L["Item values reset!"] = true
L["Your bags are full"] = true
L["Ok"] = true
L["Clear character's total points"] = true
L["Resets a character's total points to zero"] = true
L["Clear all character's total points"] = true
L["Resets all character's total points to zero"] = true
L["Reset All Totals"] = true
L["Reset Total"] = true
L["Maximum Points"] = true
L["Set Maximum Points (until reset)"] = true
L["usage: /mr maxPoints ##"] = true
