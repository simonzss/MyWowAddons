TargetText = {}

function TargetText:OnLoad()
    TargetTextFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    -- 读蓝条时就会触发PLAYER_ENTERING_WORLD事件
    TargetTextFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
end

function TargetText:OnEvent(event, unit)
    if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_TARGET_CHANGED" then
        self:UpdateAll()
    elseif unit == "target " then
        if event == "UNIT_NAME_UPDATE" then
            self:UpdateName()
        elseif event == "UNIT_LEVEL" or event == "UNIT_CLASSIFICATION_CHANGED" then --单位分类改变，即是否精英怪首领怪
            self:UpdateLevel()
        elseif event == "UNIT_FACTION" then
            self:UpdateFaction()
            self:UpdateReaction()
            self:UpdateLevel()
            self:UpdatePvP() --这里加了一句
        elseif event == "UNIT_PVP_UPDATE" then
            -- UNIT_PVP_UPDATE已经被移除，用UNIT_FACTION代替
            self:UpdatePvP()
        elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
            self:UpdateHealth()
        elseif event == "UNIT_DISPLAYPOWER" then
            -- UNIT_DISPLAYPOWER当单位的魔法类型改变时触发。在德鲁伊变形以及某些其他情况下发生。
            self:UpdatePowerType()
        elseif event == "UNIT_POWER_UPDATE" then
            self:UpdateMana()
        end
    -- Rest of the events will go her e
    end
end

local events = {
    "UNIT_NAME_UPDATE",
    "UNIT_LEVEL",
    "UNIT_CLASSIFICATION_CHANGED",
    "UNIT_FACTION",
    "UNIT_PVP_UPDATE",
    "UNIT_HEALTH",
    "UNIT_MAXHEALTH",
    "UNIT_POWER_UPDATE"
}

local colors = {
    white = {r = 1, g = 1, b = 1},
    blue = {r = 0, g = 0, b = 1}
}

local reactionNames = {
    "Extremely Hostile",
    "Very Hostile",
    "Hostile",
    "Neutral",
    "Friendly",
    "Very Friendly",
    "Extremely Friendly"
}

local HOSTILE = 2
local NEUTRAL = 4
local FRIENDLY = 6

function TargetText:RegisterUpdates()
    for _, event in ipairs(events) do
        TargetTextFrame:RegisterEvent(event)
    end
end

function TargetText:UnregisterUpdates()
    for _, event in ipairs(events) do
        TargetTextFrame:UnregisterEvent(event)
    end
end

function TargetText:UpdateAll()
    if UnitExists("target") then
        TargetTextFrame:Show()
        self:UpdateName()
        self:UpdateLevel()
        self:UpdateClass()
        self:UpdateReaction()
        self:UpdateFaction()
        self:UpdatePvP()
        self:UpdateHealth()
        self:UpdatePowerType()
        self:UpdateMana()
    else
        TargetTextFrame:Hide()
    end
end

function TargetText:UpdateName()
    local name = UnitName(target) or ""
    TargetTextFrameName:SetText(name)
end

function TargetText:UpdateLevel()
    local level = UnitLevel("target")
    local color
    if UnitCanAttack("player", "target") then
        color = GetQuestDifficultyColor(level)
    else
        color = colors.white
    end

    if level == -1 then
        level = "??"
    end

    local classification = UnitClassification("target")
    if classification == "worldboss" or classification == "rareelite" or classification == "elite" then
        level = level .. "+"
    end

    TargetTextFrameLevel:SetText(level)
    TargetTextFrameLevel:SetTextColor(color.r, color.g, color.b)
end

function TargetText:UpdateClass()
    local class, key = UnitClass("target") --UnitClass返回第一个值是本地化的职业名称，第二个是非本地化的、大写的职业名称
    local color = RAID_CLASS_COLORS[key]
    --RAID_CLASS_COLORS的定义在https://github.com/Gethe/wow-ui-source/blob/9.0.1/SharedXML/ColorUtil.lua#L25
    TargetTextFrameClass:SetText(class)
    TargetTextFrameClass:SetTextColor(color.r, color.g, color.b)
end

function TargetText:UpdateReaction()
    local description, color = "No Reaction", colors.blue
    if UnitisDead("target") then
        color = GRAY_FONT_COLOR
        if UnitisCorpse("target") then
            description = "Corpse"
        elseif UnitisGhost("target") then
            description = "Ghost"
        else
            description = "Dead"
        end
    elseif UnitPlayerControlled("target") then
        if not UnitisConnected("target") then
            description = "Disconnected"
            color = GRAY_FONT_COLOR
        elseif UnitCanAttack("target ", "player") and UnitCanAttack("player", "target ") then
            description = reactionNames[HOSTILE] --HOSTIL=2 是自己定义的，reactionNames也是自己定义的
            color = UnitReactionColor[HOSTILE] --UnitReactionColor查不到
        elseif UnitCanAttack("player", "target") then
            description = "Attackable"
            color = UnitReactionColor[NEUTRAL]
        elseif UnitisPVP("target") and not UnitIsPVPSanctuary("target") and not UnitlsPVPSanctuary("player") then
            --被插旗的玩家应该被标记为友善的
            description = reactionNames[FRIENDLY]
            color = UnitReactionColor[FRIENDLY]
        end
    elseif UnitisTapped("target") and not UnitisTappedByPlayer("target") then
        description = "Tapped"
        color = GRAY_FONT_COLOR
    else
        local reaction = UnitReaction("target", "player")
        if reaction then
            description = reactionNames[reaction]
            color = UnitReactionColor[reaction]
        end
    end
    TargetTextFrameReaction:SetText(description)
    TargetTextFrameReaction:SetTextColor(color.r, color.g, color.b)
end

function TargetText:UpdateFaction() --Faction阵营
    local faction = select(2, UnitFactionGroup("target"))
    local color
    if not faction then
        color = NORMAL_FONT_COLOR
        faction = "No Faction"
    elseif faction == select(2, UnitFactionGroup("player")) then
        color = GREEN_FONT_COLOR
    else
        color = RED_FONT_COLOR
    end
    TargetTextFrameFaction:SetText(faction)
    TargetTextFrameFaction:SetTextColor(color.r, color.g, color.b)
end

function TargetText:UpdatePvP()
    if UnitIsPVP("target") then
        TargetTextFramePvP:Show()
    else
        TargetTextFramePvP:Hide()
    end
end

function TargetText:UpdateHealth()
    local health, maxHealth = UnitHealth("target"), UnitHealthMax("target")
    local percent = health / maxHealth
    local healthText
    if maxHealth == 0 then
        healthText = "N/A"
    elseif maxHealth == 100 then
        healthText = string.format("%.0f%%", percent * 100)
    else
        healthText = string.format("%d/%d (%.0f%%)", health, maxHealth, percent * 100)
    end
    TargetTextFrameHealth:SetText(healthText)
    TargetTextFrameHealth:SetTextColor(self:GetHealthColor(percent))
end

function TargetText:UpdatePowerType()
    -- local info = ManaBarColor[UnitPowerType("target")] --ManaBarColor应该已经不用了
    local info = PowerBarColor[UnitPowerType("target")]
    TargetTextFrameManaLabel:SetText(info.prefix) --这句可能不起作用，新的Interface/FrameXML/UnitFrame.lua里面没有prefix了
    TargetTextFrameMana:SetTextColor(info.r, info.g, info.b)
end

function TargetText:UpdateMana()
    local mana, maxMana = UnitPower("target"), UnitPowerMax("target")
    local percent = mana / maxMana
    local manaText
    if maxMana == 0 then
        manaText = "N/A"
    else
        --%d接受一个数字并将其转化为有符号的整数格式,为进一步细化格式, 可以在%号后添加参数. 参数将以如下的顺序读入
        --%6.1f接受一个数字并将其转化为浮点数格式，表示一共6位浮点数，小数位数1位
        --%%接受一个百分号并转为文本形式
        manaText = string.format("%d/%d (%.0f%%)", mana, maxMana, percent * 100) --2500/3000(83%）
    end
    TargetTextFrameMana:SetText(manaText)
end

function TargetText:GetHealthColor(percent)
    local red, green
    if percent >= 0.5 then
        red = (1 - percent) * 2
        green = 1
    else
        red = 1
        green = percent * 2
    end
    return red, green, 0
end
