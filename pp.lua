print("pp activated.")

-- Map chat events to setting keys
local eventToSetting = {
    CHAT_MSG_SAY = "SAY",
    CHAT_MSG_YELL = "YELL",
    CHAT_MSG_PARTY = "PARTY",
    CHAT_MSG_PARTY_LEADER = "PARTY",
    CHAT_MSG_GUILD = "GUILD",
    CHAT_MSG_OFFICER = "OFFICER",
    CHAT_MSG_RAID = "RAID",
    CHAT_MSG_RAID_LEADER = "RAID",
    CHAT_MSG_INSTANCE_CHAT = "INSTANCE_CHAT",
    CHAT_MSG_INSTANCE_CHAT_LEADER = "INSTANCE_CHAT",
    CHAT_MSG_CHANNEL = "CHANNEL",
}

local frame = CreateFrame("Frame")

-- Register events
for event, _ in pairs(eventToSetting) do
    frame:RegisterEvent(event)
end

-- Register ADDON_LOADED to initialize our SavedVariables
frame:RegisterEvent("ADDON_LOADED")

-- Function to handle events
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "pp" then
            -- Initialize settings if they don't exist
            if type(PPSettings) ~= "table" then
                PPSettings = {}
            end
            
            -- Apply defaults for any missing settings
            local defaults = {
                MASTER = true,
                SAY = true,
                YELL = true,
                PARTY = true,
                GUILD = true,
                OFFICER = true,
                RAID = true,
                INSTANCE_CHAT = true,
                CHANNEL = false, -- General/Trade channels off by default to avoid spam
            }
            
            for k, v in pairs(defaults) do
                if PPSettings[k] == nil then
                    PPSettings[k] = v
                end
            end
        end
        return
    end

    -- Check if the master toggle is off
    if not PPSettings["MASTER"] then
        return
    end

    local text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons = ...

    -- Check if the event's channel is enabled in settings
    local settingKey = eventToSetting[event]
    if not settingKey or not PPSettings[settingKey] then
        return
    end

    -- Check if the text is exactly "!pp"
    if text == "!pp" then
        
        -- Midnight instance restriction check
        local inInstance, instanceType = IsInInstance()
        if inInstance then
            -- Note: We still attempt to reply here, but Midnight restrictions might silently block 
            -- SendChatMessage or the CHAT_MSG_* events entirely while inside an instance.
        end

        -- Generate length
        local lengthRoll = math.random(1, 20)
        
        -- Generate rarity
        local rarityRoll = math.random(1, 100)
        local rarityTag = ""
        if rarityRoll <= 70 then
            rarityTag = "[Common] "
        elseif rarityRoll <= 85 then
            rarityTag = "[Uncommon] "
        elseif rarityRoll <= 95 then
            rarityTag = "[Rare] "
        elseif rarityRoll <= 99 then
            rarityTag = "[Epic] "
        else
            rarityTag = "[Legendary] "
        end
        
        -- Generate shaft character
        local shaftRoll = math.random(1, 100)
        local shaftChar = "="
        if shaftRoll <= 70 then
            shaftChar = "="
        elseif shaftRoll <= 90 then
            shaftChar = "≡"
        else
            shaftChar = "≈"
        end
        
        -- Generate mirrored state (1% chance)
        local isMirrored = math.random(1, 100) == 1
        
        -- Construct the PP
        local ppBase = ""
        if isMirrored then
            ppBase = "C" .. string.rep(shaftChar, lengthRoll) .. "8"
            -- Apply special effect for 20
            if lengthRoll == 20 then
                ppBase = "~ ~ " .. ppBase
            end
        else
            ppBase = "8" .. string.rep(shaftChar, lengthRoll) .. "D"
            -- Apply special effect for 20
            if lengthRoll == 20 then
                ppBase = ppBase .. " ~ ~"
            end
        end
        
        -- Construct the final response string
        local ppString = rarityTag .. "(" .. lengthRoll .. ") " .. ppBase
        
        local chatType = settingKey
        local target = nil
        
        -- CHANNEL requires the channelIndex as the target
        if chatType == "CHANNEL" then
            target = channelIndex
        end
        
        -- Send the constructed message back to the channel.
        SendChatMessage(ppString, chatType, nil, target)
    end
end)

-- Slash Command to open the settings menu
SLASH_PP1 = "/pp"
SlashCmdList["PP"] = function(msg)
    msg = string.lower(strtrim(msg or ""))
    
    if msg == "on" then
        PPSettings["MASTER"] = true
        print("pp addon is now ON.")
        if PPOptionsFrame and PPOptionsFrame:IsShown() then
            -- Update UI if it's currently open
            if _G["PPCheckMaster"] then _G["PPCheckMaster"]:SetChecked(true) end
        end
    elseif msg == "off" then
        PPSettings["MASTER"] = false
        print("pp addon is now OFF.")
        if PPOptionsFrame and PPOptionsFrame:IsShown() then
            -- Update UI if it's currently open
            if _G["PPCheckMaster"] then _G["PPCheckMaster"]:SetChecked(false) end
        end
    else
        if not PPOptionsFrame then
            CreatePPOptionsFrame()
        end
        
        if PPOptionsFrame:IsShown() then
            PPOptionsFrame:Hide()
        else
            PPOptionsFrame:Show()
            -- Refresh checkboxes to match current settings when opened
            if _G["PPCheckMaster"] then _G["PPCheckMaster"]:SetChecked(PPSettings["MASTER"]) end
            if _G["PPCheckSay"] then _G["PPCheckSay"]:SetChecked(PPSettings["SAY"]) end
            if _G["PPCheckYell"] then _G["PPCheckYell"]:SetChecked(PPSettings["YELL"]) end
            if _G["PPCheckParty"] then _G["PPCheckParty"]:SetChecked(PPSettings["PARTY"]) end
            if _G["PPCheckGuild"] then _G["PPCheckGuild"]:SetChecked(PPSettings["GUILD"]) end
            if _G["PPCheckOfficer"] then _G["PPCheckOfficer"]:SetChecked(PPSettings["OFFICER"]) end
            if _G["PPCheckRaid"] then _G["PPCheckRaid"]:SetChecked(PPSettings["RAID"]) end
            if _G["PPCheckInstance"] then _G["PPCheckInstance"]:SetChecked(PPSettings["INSTANCE_CHAT"]) end
            if _G["PPCheckChannel"] then _G["PPCheckChannel"]:SetChecked(PPSettings["CHANNEL"]) end
        end
    end
end

-- Function to create the standalone settings frame
function CreatePPOptionsFrame()
    -- Create a basic frame with an inset and a close button
    local f = CreateFrame("Frame", "PPOptionsFrame", UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(300, 350)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    
    -- Frame Title
    f.title = f:CreateFontString(nil, "OVERLAY")
    f.title:SetFontObject("GameFontHighlight")
    f.title:SetPoint("CENTER", f.TitleBg, "CENTER", 0, 0)
    f.title:SetText("pp Settings")

    -- Helper function to create checkboxes
    local function CreateCheckbox(parent, name, label, settingKey, yOffset)
        -- We use UICheckButtonTemplate which is standard for most generic checkboxes
        local cb = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", 20, yOffset)
        
        -- Set the label text
        _G[cb:GetName() .. "Text"]:SetText(label)
        
        -- Initialize the checkbox state
        cb:SetChecked(PPSettings[settingKey])
        
        -- Save the setting when clicked
        cb:SetScript("OnClick", function(self)
            PPSettings[settingKey] = self:GetChecked()
        end)
        
        return cb
    end

    -- Create the checkboxes
    CreateCheckbox(f, "PPCheckMaster", "Master Enable/Disable", "MASTER", -40)
    CreateCheckbox(f, "PPCheckSay", "Say", "SAY", -70)
    CreateCheckbox(f, "PPCheckYell", "Yell", "YELL", -100)
    CreateCheckbox(f, "PPCheckParty", "Party", "PARTY", -130)
    CreateCheckbox(f, "PPCheckGuild", "Guild", "GUILD", -160)
    CreateCheckbox(f, "PPCheckOfficer", "Officer", "OFFICER", -190)
    CreateCheckbox(f, "PPCheckRaid", "Raid", "RAID", -220)
    CreateCheckbox(f, "PPCheckInstance", "Instance", "INSTANCE_CHAT", -250)
    CreateCheckbox(f, "PPCheckChannel", "General/Trade Channels", "CHANNEL", -280)
    
    -- Hide it initially
    f:Hide()
end