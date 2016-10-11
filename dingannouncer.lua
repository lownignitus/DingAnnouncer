-- Title: Ding Announcer
-- Author: LownIgnitus
-- Version: 1.0.0
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

-- RegisterForEvent table
local daEvents_table = {}

daEvents_table.eventFrame = CF("Frame");
daEvents_table.eventFrame:RegisterEvent("ADDON_LOADED");
daEvents_table.eventFrame:RegisterEvent("PLAYER_LEVEL_UP");
daEvents_table.eventFrame:RegisterEvent("PLAYER_XP_UPDATE");
daEvents_table.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
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
			["daChannel"] = "g",
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
	daOptionsInit();
	daInitialize();
end

-- Options
function daOptionsInit()
	local daOptions = CF("Frame", nil, InterfaceOptionsFramePanelContainer);
	local panelWidth = InterfaceOptionsFramePanelContainer:GetWidth() -- ~623
	local wideWidth = panelWidth - 40
	daOptions:SetWidth(wideWidth)
	daOptions:Hide();
	daOptions.name = "|cff00ff00Ding Announcer|r"
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
	local desc2 = cf("GameFontHighlight", GetAddOnMetadata(addon_name, "X-Notes2"))
	desc2:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -8)

	-- Options
	local daOptionsFrame = CF("Frame", DAOptionsFrame, daOptions)
	daOptionsFrame:SetPoint("TOPLEFT", desc2, "BOTTOMLEFT", 0, -8)
	daOptionsFrame:SetBackdrop(daOptionsBG)
	daOptionsFrame:SetSize(450, 215)

	local optionsTitle = cf("GameFontNormal", nil, nil, nil, "TOP", daOptionsFrame, "TOP", 250, 16, 35, -8, "Ding Announcer Options")

	-- Enable addon, 
	local daAutoToggle = ccb("Toggle Auto Announce", 18, 18, "TOPLEFT", optionsTitle, "TOPLEFT", -130, -16, "daAutoToggle")
	daAutoToggle:SetScript("OnClick", function(self) 
--		print("Toggle")
		if daAutoToggle:GetChecked() == true then
--			print("true")
			daSettings.options.daActivate = true
		else
--			print("false")
			daSettings.options.daActivate = false
		end
	end)

	-- Pick and Set chat to announce to
	local daChatOptTitle = cf("GameFontNormal", nil, nil, nil, "TOPLEFT", daAutoToggle, "BOTTOMLEFT", 250, 16, 2, -8, "Select Chat Channel to use.")
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
	DAChatOptText:SetText("Chat Channel")
	
	-- Enable Auto Announcing at 25% 50% & 75%
	local daPercentToggle = ccb("Toggle reporting when at 25%, 50%, & 75% of level.", 18, 18, "TOPLEFT", daChatOpt, "BOTTOMLEFT", 6, -8, "daPercentToggle")
	daPercentToggle:SetScript("OnClick", function(self) 
--		print("Toggle")
		if daPercentToggle:GetChecked() == true then
--			print("true")
			daSettings.options.daPercent = true
		else
--			print("false")
			daSettings.options.daPercent = false
		end
	end)

	-- Enable reporting Percentage left to level
	local daPercentLeftToggle = ccb("Change percent reporting to amount left to level.", 18, 18, "TOPLEFT", daPercentToggle, "BOTTOMLEFT", 0, -8, "daPercentLeftToggle")
	daPercentLeftToggle:SetScript("OnClick", function(self) 
--		print("Toggle")
		if daPercentLeftToggle:GetChecked() == true then
--			print("true")
			daSettings.options.daPercentLeft = true
		else
--			print("false")
			daSettings.options.daPercentLeft = false
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

	curXp = UnitXP("player")/UnitXPMax("player")
	perCount = math.floor(curXp * 4)
end

function daEvents_table.eventFrame:PLAYER_ENTERING_WORLD()
	-- body
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
	if daSettings.options.daActivate == true then
		daChatFunc(curLevel)
	end 
end

function daChatFunc(curLevel)
--	print("In daChatFunc")
	if daSettings.options.daChannel == "General" then
		index = "1"
	elseif daSettings.options.daChannel == "Trade" then
		index = "2"
	end
	
	curLevel = UnitLevel("player")	
	if daSettings.options.daPercent == true and ding == "no" then
--		print("In daPercent")
		curXp = UnitXP("player")/UnitXPMax("player")
--		print(perCount)
		if daSettings.options.daPercentLeft == false then
			if curXp >= 0.75 and perCount<3 then
				message = "I just hit 75% of level " .. curLevel .. "!"
				daSendMsg(message, index)
			elseif curXp >= 0.25 and perCount<1 then
				message = "I just hit 25% of level " .. curLevel .. "!"
				daSendMsg(message, index)
			elseif curXp >= 0.5  and perCount<2 then
				message = "I just hit 50% of level " .. curLevel .. "!"
				daSendMsg(message, index)
			elseif curXp <= 0.25 then
				--
			end
		else
--			print("In daPercentLeft")
			if curXp >= 0.75 and perCount<3 then
				message = "Only 25% left until level " .. curLevel+1 .. "!"
				daSendMsg(message, index)
			elseif curXp >= 0.25 and perCount<1 then
				message = "Only 75% left until level " .. curLevel+1 .. "!"
				daSendMsg(message, index)
			elseif curXp >= 0.5 and perCount<2 then
				message = "Only 50% left until level " .. curLevel+1 .. "!"
				daSendMsg(message, index)		
			elseif curXp <= 0.25 then
				--
			end
		end
	elseif ding == "yes" then
--		print("Level message")
		ding = "no"
		curLevel = curLevel + 1
		message = "I just hit level " .. curLevel .. "!"
		daSendMsg(message, index)
	end
	perCount = math.floor(curXp * 4)
--	print(perCount)
end

function daSendMsg(message, index)
	print("in daSendMsg")
	if (index ~= nil) and daSettings.options.daChannel == "General" or daSettings.options.daChannel == "Trade" then
		SendChatMessage(message, "CHANNEL", nil, index)
	else
		SendChatMessage(message, daSettings.options.daChannel)
	end
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