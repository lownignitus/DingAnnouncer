-- Title: Ding Announcer
-- Author: LownIgnitus
-- Version: 1.1.2
-- Desc: Announces to set chat when you ding
-- And can also announce % of level or % to next level

CF = CreateFrame
local addon_name = "DingAnnouncer"
local curLevel = 0
local curXp = 0
local index = ""
local message = ""
local ding = "no"
local perCount = 0
local reported = false
SLASH_DINGANNOUNCER1, SLASH_DINGANNOUNCER2, SLASH_DINGANNOUNCER3, SLASH_DINGANNOUNCER4 = "/da", "/DA", "/DingAnnouncer", "/dingannouncer"

-- RegisterForEvent table
local daEvents_table = {}

daEvents_table.eventFrame = CF("Frame");
daEvents_table.eventFrame:RegisterEvent("ADDON_LOADED");
daEvents_table.eventFrame:SetScript("OnEvent", function(self, event, ...)
	daEvents_table.eventFrame[event](self, ...);
end);

function daEvents_table.eventFrame:ADDON_LOADED(AddOn)
	if AddOn ~= addon_name then
		return -- not my addon
	end

	-- unregister ADDON_LOADED
	daEvents_table.eventFrame:UnregisterEvent("ADDON_LOADED")

	-- Defaults
	local deafults = {
		["options"] = {
			["daActivate"] = true,
			["daAddOnName"] = true,
			["daChannel"] = "SAY",
			["daChannel2Toggle"] = false,
			["daChannel2"] = "GUILD",
			["daPercent"] = false,
			["daPercentLeft"] = false,
		}
	}

	local function daSVCheck(src, dst)
		if type(src) ~= "table" then return {} end
		if type(dst) ~= "table" then dst = {} end
		for k, v in pairs(src) do
			if type(v) == "table" then
				dst[k] = daSVCheck(v, dst[k])
			elseif type(v) ~= type(dst[k]) then
				dst[k] = v
			end
		end
		return dst
	end

	daSettings = daSVCheck(deafults, daSettings)

	daEvents_table.eventFrame:RegisterEvent("PLAYER_LEVEL_UP");
	daEvents_table.eventFrame:RegisterEvent("PLAYER_XP_UPDATE");

	daOptionsInit();
	daInitialize();
end

function daEvents_table.eventFrame:PLAYER_LEVEL_UP()
--	print("PLAYER_LEVEL_UP")
	if daSettings.options.daActivate == true then
		ding = "yes"
		daChatFunc(curLevel)
	end
end

function daEvents_table.eventFrame:PLAYER_XP_UPDATE()
--	print("PLAYER_XP_UPDATE")
	if daSettings.options.daActivate == true and daSettings.options.daPercent == true then
		daChatFunc(curLevel)
	end 
end

-- Options
function daOptionsInit()
	local daOptions = CF("Frame", "daOptionsPanel", InterfaceOptionsFramePanelContainer);
	local panelWidth = InterfaceOptionsFramePanelContainer:GetWidth() -- ~623
	local wideWidth = panelWidth - 40
	daOptions:SetWidth(wideWidth)
	daOptions:Hide();
	daOptions.name = GetAddOnMetadata(addon_name, "Title")
	daOptionsBG = {edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, edgeSize = 16}

	-- Special thanks to Ro for inspiration for the overall structure of this options panel (and the title/version/description code)
	local function cf(fontName, r, g, b, anchorPoint, relativeto, relativePoint, cx, cy, xoff, yoff, text)
		local font = daOptions:CreateFontString(nil, "BACKGROUND", fontName)
		font:SetJustifyH("LEFT")
		font:SetJustifyV("TOP")
		if type(r) == "string" then -- r is text, not position
			text = r
		else
			if r then
				font:SetTextColor(r, g, b, 1)
			end
			font:SetSize(cx, cy)
			font:SetPoint(anchorPoint, relativeto, relativePoint, xoff, yoff)
		end
		font:SetText(text)
		return font
	end

	-- Special thanks to Hugh & Simca for checkbox creation 
	local function ccb(text, cx, cy, anchorPoint, relativeto, relativePoint, xoff, yoff, frameName, font)
		local checkbox = CF("CheckButton", frameName, daOptions, "UICheckButtonTemplate")
		checkbox:SetPoint(anchorPoint, relativeto, relativePoint, xoff, yoff)
		checkbox:SetSize(cx, cy)
		local checkfont = font or "GameFontNormal"
		checkbox.text:SetFontObject(checkfont)
		checkbox.text:SetText(" " .. text)
		return checkbox
	end

	local title = cf("SystemFont_OutlineThick_WTF", GetAddOnMetadata(addon_name, "Title"))
	title:SetPoint("TOPLEFT", 16, -16)
	local ver = cf("SystemFont_Huge1", GetAddOnMetadata(addon_name, "Version"))
	ver:SetPoint("BOTTOMLEFT", title, "BOTTOMRIGHT", 4, 0)
	local date = cf("GameFontNormalLarge", "Version Date: " .. GetAddOnMetadata(addon_name, "X-Date"))
	date:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
	local author = cf("GameFontNormal", "Author: " .. GetAddOnMetadata(addon_name, "Author"))
	author:SetPoint("TOPLEFT", date, "BOTTOMLEFT", 0, -8)
	local website = cf("GameFontNormal", "Website: " .. GetAddOnMetadata(addon_name, "X-Website"))
	website:SetPoint("TOPLEFT", author, "BOTTOMLEFT", 0, -8)
	local desc = cf("GameFontHighlight", GetAddOnMetadata(addon_name, "X-Notes"))
	desc:SetPoint("TOPLEFT", website, "BOTTOMLEFT", 0, -8)

	-- Options
	local daOptFrame = CF("Frame", DAOptFrame, daOptions)
	daOptFrame:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -8)
	daOptFrame:SetBackdrop(daOptionsBG)
	daOptFrame:SetSize(450, 290)

	local optTitle = cf("GameFontNormal", nil, nil, nil, "TOP", daOptFrame, "TOP", 250, 16, 35, -8, "Ding Announcer Options")

	-- Enable addon, 
	local daAutoToggle = ccb("Toggle Auto Announce", 18, 18, "TOPLEFT", optTitle, "TOPLEFT", -130, -16, "daAutoToggle")
	
	daAutoToggle:SetScript("OnClick", function(self) daAuto() end)

	local daAddonAdToggle = ccb("Toggle Addon name in Announce", 18, 18, "TOPLEFT", daAutoToggle, "TOPLEFT", 0, -20, "daAddonAdToggle")
	daAddonAdToggle:SetScript("OnClick", function(self)	daAddOnName() end)

	-- Pick and Set chat to announce to
	local daChatOptTitle = cf("GameFontNormal", nil, nil, nil, "TOPLEFT", daAddonAdToggle, "BOTTOMLEFT", 250, 16, 2, -8, "Select Chat Channel to use.")
	local info = {}
	local daChatOpt = CF("Frame", "DAChatOpt", daOptions, "UIDropDownMenuTemplate")
	daChatOpt:SetPoint("TOPLEFT", daChatOptTitle, "BOTTOMLEFT", -8, -8)
	daChatOpt.initialize = function()
		wipe(info)
		local names = {"Guild Chat", "Party Chat", "Instance Chat", "Say Aloud", "Yell Aloud", "Local Chat", "Trade Chat"}
		local chats = {"GUILD", "PARTY", "INSTANCE_CHAT", "SAY", "YELL", "General", "Trade"}
		for i, chat in next, chats do
			info.text = names[i]
			info.value = chat
			info.func = function(self)
				daSettings.options.daChannel = self.value
				DAChatOptText:SetText(self:GetText())
--				print(self.value)
			end
			info.checked = chat == daSettings.options.daChannel
			UIDropDownMenu_AddButton(info)
		end
	end
	DAChatOptText:SetText(daSettings.options.daChannel)

	-- Enable option to print to a second channel simultaneously
	local daChat2Toggle =ccb("Toggle ability to print to a 2nd channel simultaneously.", 18, 18, "TOPLEFT", daChatOpt, "BOTTOMLEFT", 6, -8, "daChat2Toggle")
	daChat2Toggle:SetScript("OnClick", function(self)
		if daChat2Toggle:GetChecked() == true then
			daSettings.options.daChannel2Toggle = true
			ChatFrame1:AddMessage("|cFF00FF00Ding Announcer is now reporting to 2 channels simultaneously|r!")
		else
			daSettings.options.daChannel2Toggle = false
			ChatFrame1:AddMessage("|cFF00FF00Ding Announcer is no longer reporting to 2 channels simultaneously|r!")
		end
	end)

	-- Pick and Set chat to announce to simultaneously
	local daChat2OptTitle = cf("GameFontNormal", nil, nil, nil, "TOPLEFT", daChat2Toggle, "BOTTOMLEFT", 250, 16, 2, -8, "Select Chat Channel to use.")
	local info2 = {}
	local daChat2Opt = CF("Frame", "DAChat2Opt", daOptions, "UIDropDownMenuTemplate")
	daChat2Opt:SetPoint("TOPLEFT", daChat2OptTitle, "BOTTOMLEFT", -8, -8)
	daChat2Opt.initialize = function()
		wipe(info2)
		local names2 = {"Guild Chat", "Party Chat", "Instance Chat", "Say Aloud", "Yell Aloud", "Local Chat", "Trade Chat"}
		local chats2 = {"GUILD", "PARTY", "INSTANCE_CHAT", "SAY", "YELL", "General", "Trade"}
		for i, chat2 in next, chats2 do
			info2.text = names2[i]
			info2.value = chat2
			info2.func = function(self)
				daSettings.options.daChannel2 = self.value
				DAChat2OptText:SetText(self:GetText())
--				print(self.value)
			end
			info2.checked = chat2 == daSettings.options.daChannel2
			UIDropDownMenu_AddButton(info2)
		end
	end
	DAChat2OptText:SetText(daSettings.options.daChannel2) 
	
	-- Enable Auto Announcing at 25% 50% & 75%
	local daPercentToggle = ccb("Toggle reporting when at 25%, 50%, & 75% of level.", 18, 18, "TOPLEFT", daChat2Opt, "BOTTOMLEFT", 6, -8, "daPercentToggle")
	daPercentToggle:SetScript("OnClick", function(self) 
--		print("Toggle")
		if daPercentToggle:GetChecked() == true then
--			print("true")
			daSettings.options.daPercent = true
			ChatFrame1:AddMessage("|cFF00FF00Ding Announcer is now reporting Percentage|r!")
		else
--			print("false")
			daSettings.options.daPercent = false
			ChatFrame1:AddMessage("|cFFFFF0000Ding Announcer is no longer reporting Percentage|r!")
		end
	end)

	-- Enable reporting Percentage left to level
	local daPercentLeftToggle = ccb("Change percent reporting to amount left to level.", 18, 18, "TOPLEFT", daPercentToggle, "BOTTOMLEFT", 0, -8, "daPercentLeftToggle")
	daPercentLeftToggle:SetScript("OnClick", function(self) 
--		print("Toggle")
		if daPercentLeftToggle:GetChecked() == true then
--			print("true")
			daSettings.options.daPercentLeft = true
			ChatFrame1:AddMessage("|cFF00FF00Ding Announcer is now reporting Percentage Left|r!")
		else
--			print("false")
			daSettings.options.daPercentLeft = false
			ChatFrame1:AddMessage("|cFFFFF0000Ding Announcer is no longer reporting Percentage Left|r!")
		end
	end)

	function daOptions.okay()
		daOptions:Hide();
	end

	function daOptions.cancel()
		daOptions:Hide();
	end

	function daOptions.default()
		daReset();
	end

	InterfaceOptions_AddCategory(daOptions);
end

function daInitialize()
	if daSettings.options.daActivate == true then
		daAutoToggle:SetChecked(true)
	else
		daAutoToggle:SetChecked(false)
	end

	if daSettings.options.daAddOnName == true then
		daAddonAdToggle:SetChecked(true)
	else
		daAddonAdToggle:SetChecked(false)
	end

	if daSettings.options.daChannel2Toggle == true then
		daChat2Toggle:SetChecked(true)
	else
		daChat2Toggle:SetChecked(false)
	end

	if daSettings.options.daPercent == true then
		daPercentToggle:SetChecked(true)
	else
		daPercentToggle:SetChecked(false)
	end

	if daSettings.options.daPercentLeft == true then
		daPercentLeftToggle:SetChecked(true)
	else
		daPercentLeftToggle:SetChecked(false)
	end

	curLevel = UnitLevel("player")
	curXp = UnitXP("player")/UnitXPMax("player")
	perCount = math.floor(curXp * 4)
end

function daChatFunc(curLevel)
--	print("In daChatFunc")
	if daSettings.options.daChannel == "General" then
		index1 = "1"
	elseif daSettings.options.daChannel == "Trade" then
		index1 = "2"
	else
		index1 = daSettings.options.daChannel
	end

	if daSettings.options.daChannel2Toggle == true then
		if daSettings.options.daChannel2 == "General" then
			index2 = "1"
		elseif daSettings.options.daChannel2 == "Trade" then
			index2 = "2"
		else
			index2 = daSettings.options.daChannel2
		end
	end
	
	curLevel = UnitLevel("player")	
	if daSettings.options.daPercent == true and ding == "no" then
--		print("In daPercent")
		curXp = UnitXP("player")/UnitXPMax("player")
--		print(perCount)
		if daSettings.options.daPercentLeft == false then
			if curXp >= 0.75 and perCount<3 then
				if daSettings.options.daAddOnName == true then
					message = "[Ding Announcer]: I just hit 75% of level " .. curLevel .. "!"
				else
					message = "I just hit 75% of level " .. curLevel .. "!"
				end
				if daSettings.options.daChannel2Toggle == false then
					daSendMsg(message, index1, 1)
				elseif daSettings.options.daChannel2Toggle == true then
					daSendMsg(message, index1, 1)
					daSendMsg(message, index2, 2)
				end	
			elseif curXp >= 0.25 and perCount<1 then
				if daSettings.options.daAddOnName == true then
					message = "[Ding Announcer]: I just hit 25% of level " .. curLevel .. "!"
				else
					message = "I just hit 25% of level " .. curLevel .. "!"
				end
				if daSettings.options.daChannel2Toggle == false then
					daSendMsg(message, index1, 1)
				elseif daSettings.options.daChannel2Toggle == true then
					daSendMsg(message, index1, 1)
					daSendMsg(message, index2, 2)
				end	
			elseif curXp >= 0.5  and perCount<2 then
				if daSettings.options.daAddOnName == true then
					message = "[Ding Announcer]: I just hit 50% of level " .. curLevel .. "!"
				else
					message = "I just hit 50% of level " .. curLevel .. "!"
				end
				if daSettings.options.daChannel2Toggle == false then
					daSendMsg(message, index1, 1)
				elseif daSettings.options.daChannel2Toggle == true then
					daSendMsg(message, index1, 1)
					daSendMsg(message, index2, 2)
				end	
			elseif curXp <= 0.25 then
				--
			end
		else
--			print("In daPercentLeft")
			if curXp >= 0.75 and perCount<3 then
				if daSettings.options.daAddOnName == true then
					message = "[Ding Announcer]: Only 25% left until level " .. curLevel+1 .. "!"
				else
					message = "Only 25% left until level " .. curLevel+1 .. "!"
				end
				if daSettings.options.daChannel2Toggle == false then
					daSendMsg(message, index1, 1)
				elseif daSettings.options.daChannel2Toggle == true then
					daSendMsg(message, index1, 1)
					daSendMsg(message, index2, 2)
				end	
			elseif curXp >= 0.25 and perCount<1 then
				if daSettings.options.daAddOnName == true then
					message = "[Ding Announcer]: Only 75% left until level " .. curLevel+1 .. "!"
				else
					message = "Only 75% left until level " .. curLevel+1 .. "!"
				end
				if daSettings.options.daChannel2Toggle == false then
					daSendMsg(message, index1, 1)
				elseif daSettings.options.daChannel2Toggle == true then
					daSendMsg(message, index1, 1)
					daSendMsg(message, index2, 2)
				end	
			elseif curXp >= 0.5 and perCount<2 then
				if daSettings.options.daAddOnName == true then
					message = "[Ding Announcer]: Only 50% left until level " .. curLevel+1 .. "!"
				else
					message = "Only 50% left until level " .. curLevel+1 .. "!"
				end
				if daSettings.options.daChannel2Toggle == false then
					daSendMsg(message, index1, 1)
				elseif daSettings.options.daChannel2Toggle == true then
					daSendMsg(message, index1, 1)
					daSendMsg(message, index2, 2)
				end	
			elseif curXp <= 0.25 then
				--
			end
		end
	elseif ding == "yes" then
--		print("Level message")
		ding = "no"
		curLevel = curLevel + 1
		if daSettings.options.daAddOnName == true then
			message = "[Ding Announcer]: I just hit level " .. curLevel .. "!"
		else
			message = "I just hit level " .. curLevel .. "!"
		end
		if daSettings.options.daChannel2Toggle == false then
			daSendMsg(message, index1, 1)
		elseif daSettings.options.daChannel2Toggle == true then
			daSendMsg(message, index1, 1)
			daSendMsg(message, index2, 2)
		end
	elseif ding == "no" and reported == true then
		reported = false
		if daSettings.options.daAddOnName == true then
			message = "[Ding Announcer]: Just letting you know that I am currently level " .. curLevel .. "!"
		else
			message = "Just letting you know that I am currently level " .. curLevel .. "!"
		end
		if daSettings.options.daChannel2Toggle == false then
			daSendMsg(message, index1, 1)
		elseif daSettings.options.daChannel2Toggle == true then
			daSendMsg(message, index1, 1)
			daSendMsg(message, index2, 2)
		end
	end
	perCount = math.floor(curXp * 4)
--	print(perCount)
end

function daSendMsg(message, index, channel)
--	print("in daSendMsg")
--	print(message)
	if channel == 1 then
--		print("Channel 1")
		if index ~= nil and daSettings.options.daChannel == "General" or daSettings.options.daChannel == "Trade" then
--			print("General or Trade")
			SendChatMessage(message, "CHANNEL", nil, index)
		else
--			print("Not General or Trade")
			SendChatMessage(message, index)
		end
	elseif channel == 2 then
--		print("Channel 1")
		if index ~= nil and daSettings.options.daChannel2 == "General" or daSettings.options.daChannel2 == "Trade" then
--			print("General or Trade")
			SendChatMessage(message, "CHANNEL", nil, index)
		else
--			print("Not General or Trade")
			SendChatMessage(message, index)
		end
	end
end

function daAuto()
	if daSettings.options.daActivate == false then
		ChatFrame1:AddMessage("Ding Announcer is now on |cFF00FF00Auto|r!")
		daSettings.options.daActivate = true
		daAutoToggle:SetChecked(true)
	elseif daSettings.options.daActivate == true then
		ChatFrame1:AddMessage("Ding Announcer is now on |cFFFFF000Manual|r!")
		daSettings.options.daActivate = false
		daAutoToggle:SetChecked(false)
	end
end

function daAddOnName()
	if daSettings.options.daAddOnName == false then
		ChatFrame1:AddMessage("Ding Announcer is |cFF00FF00now Advertising|r!")
		daSettings.options.daAddOnName = true
		daAddonAdToggle:SetChecked(true)
	elseif daSettings.options.daAddOnName == true then
		ChatFrame1:AddMessage("Ding Announcer is now on |cFFFFF000no longer Advertising|r!")
		daSettings.options.daAddOnName = false
		daAddonAdToggle:SetChecked(false)
	end
end

function daOption()
	InterfaceOptionsFrame_OpenToCategory(GetAddOnMetadata(addon_name, "Title"));
	InterfaceOptionsFrame_OpenToCategory(GetAddOnMetadata(addon_name, "Title"));
end

function daInfo()
	ChatFrame1:AddMessage(GetAddOnMetadata(addon_name, "Title") .. " " .. GetAddOnMetadata(addon_name, "Version"))
	ChatFrame1:AddMessage("Author: " .. GetAddOnMetadata(addon_name, "Author"))
	ChatFrame1:AddMessage("Build Date: " .. GetAddOnMetadata(addon_name, "X-Date"))
end

function daReset()
	local function daSVCheck(src, dst)
		if type(src) ~= "table" then return {} end
		if type(dst) ~= "table" then dst = {} end
		for k, v in pairs(src) do
			if type(v) == "table" then
				dst[k] = daSVCheck(v, dst[k])
			else
				dst[k] = v
			end
		end
		return dst
	end

	daSettings = daSVCheck(deafults, daSettings)
end

function SlashCmdList.DINGANNOUNCER(msg)
	if msg == "auto" then
		daAuto()
	elseif msg == "advert" then
		daAddOnName()
	elseif msg == "report" then
		reported = true
		daChatFunc(curLevel)
	elseif msg == "options" then
		daOption()
	elseif msg == "info" then
		daInfo()
	else
		ChatFrame1:AddMessage("|cFF71C671Ding Announcer Slash Commands|r")
		ChatFrame1:AddMessage("|cFF71C671type /DA followed by:|r")
		ChatFrame1:AddMessage("|cFF71C671  -- auto to toggle auto announce functionality|r")
		ChatFrame1:AddMessage("|cFF71C671  -- advert to toggle addon name in announce|r")
		ChatFrame1:AddMessage("|cFF71C671  -- report to manually announce level &/or Percentage|r")
		ChatFrame1:AddMessage("|cFF71C671  -- options to open addon options|r")
		ChatFrame1:AddMessage("|cFF71C671  -- info to view current build info|r")
	end
end
