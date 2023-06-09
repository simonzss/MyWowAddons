local PlayerFramePlus = {}

-- This function will do any initial bookkeeping on loading WoW.
function PlayerFramePlus:Initialize()
    -- Create the base frame additions
   
    local frame = self.frame
    
    --Create the graphical outline out of the image file
    local border = frame:CreateTexture(nil, "OVERLAY")
	border:SetHeight(128)
    border:SetWidth(256)
    border:SetPoint("TOPLEFT", PlayerFrame, "TOPLEFT", 77, -37)
    border:SetTexture[[Interface\AddOns\PlayerFramePlus\PlayerFramePlus]]

    local xpText = frame:CreateFontString(nil, "OVERLAY",  "GameFontNormalSmall")
    xpText:SetPoint("CENTER", border, "CENTER", 0, 30)
    xpText:SetTextColor(.9, .7, 1)
    xpText:SetText("PlaceHolder")
    
    frame.xpText = xpText -- Save for future reference

    local xpBar = CreateFrame("StatusBar", nil, frame, "TextStatusBar")
    xpBar:SetWidth(218)
    xpBar:SetHeight(12)
    xpBar:SetPoint("TOPLEFT", border, "TOPLEFT", 12, -28)
    xpBar:SetStatusBarTexture[[Interface\TargetingFrame\UI-StatusBar]]
    xpBar:SetStatusBarColor(.5, 0, .75, 1)
    xpBar:SetFrameLevel("1")
    
    frame.xpBar = xpBar -- Save for future reference

    local bg = xpBar:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(0, 0, 0, .5)
    bg:SetWidth(218)
    bg:SetHeight(12)
    bg:SetPoint("BOTTOM", PlayerFrame, "BOTTOM", 84, 22)

    frame:RegisterEvent("PLAYER_XP_UPDATE")
    frame:RegisterEvent("PLAYER_LEVEL_UP")
    frame:RegisterEvent("UPDATE_EXHAUSTION")

    frame:SetScript("OnEvent", function() 
        if event == "PLAYER_XP_UPDATE" or event == "PLAYER_LEVEL_UP" or event == "UPDATE_EXHAUSTION" then
            self:ShowExp() 
        end
    end)
end

function PlayerFramePlus:ShowExp()
    local currXP, nextXP = UnitXP("player"), UnitXPMax("player")
    local restXP, percentXP =  GetXPExhaustion(), floor(currXP / nextXP * 100)
    local str
    
    if restXP then
        str = ("%s / %sxp %s%% (+%s)"):format(currXP, nextXP, percentXP, restXP/2)
    else
        str = ("%s / %sxp %s%%"):format(currXP, nextXP, percentXP )        
    end		

    self.frame.xpText:SetText(str)
        
    self.frame.xpBar:SetMinMaxValues(min(0, currXP), nextXP)
    self.frame.xpBar:SetValue(currXP)
end

local frame = CreateFrame("Frame", nil, PlayerFrame)

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function() 
    if event == "PLAYER_ENTERING_WORLD" then
        PlayerFramePlus:Initialize()
        PlayerFramePlus:ShowExp()
    end
end)

PlayerFramePlus.frame = frame

