TargetTextBuffs = {}
local buffFrames = {}
local debuffFrames = {}
local BUFFS_PER_ROW = 8
local BUFF_SPACING = 2
local BUFF_TYPE_OFFSET_Y = -7

function TargetTextBuffs:OnLoad(frame)
    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterEvent("UNIT_AURA")
end

function TargetTextBuffs:OnEvent(event, unit)
    if unit == "target" or event == "PLAYER_TARGET_CHANGED" then
        local anchorBuff = self:UpdateBuffs()
        local anchorDebuff = self:UpdateDebuffs()
        -- UpdateBuffs、UpdateDebuffs、UpdateAnchors待定义
        if UnitIsFriend("player", "target") then
            self:UpdateAnchors(buffFrames[1], debuffFrames[1], anchorBuff)
        else
            self:UpdateAnchors(debuffFrames[1], buffFrames[1], anchorDebuff)
        end
    end
end

function TargetTextBuffs:UpdateAnchors(firstFrame, secondFrame, anchorTo)
    -- UpdateAnchors是一个对增益和减益进行排序的函数
    if firstFrame and firstFrame:IsShown() then
        firstFrame:SetPoint("TOPLEFT", TargetTextBuffsFrame)
        if secondFrame and secondFrame:IsShown() then
            secondFrame:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", 0, BUFF_TYPE_OFFSET_Y)
            -- SetPoint(point [, relativeTo [, relativePoint]] [, offsetX, offsetY])
        end
    elseif secondFrame and secondFrame:IsShown() then
        secondFrame:SetPoint("TOPLEFT", TargetTextBuffsFrame)
    end
end

function TargetTextBuffs:CreateBuffBase(index, frames, name, template)
    local frame = CreateFrame("Button", name, TargetTextBuffsFrame, template)
    -- CreateFrame(frameType [, name, parent, template, id])
    frame.icon = _G[name .. "Icon"]
    frame.cooldown = _G[name .. "Cooldown"]
    frame.count = _G[name .. "Count"]
    frame.border = _G[name .. "Border"]
    frame.id = index

    local relativeTo, relativePoint, offsetX, offsetY
    if index == 1 then
        -- Use default (empty) values
    elseif index % BUFFS_PER_ROW == 1 then
        relativeTo = frames[index - BUFFS_PER_ROW]
        relativePoint = "BOTTOMLEFT"
        offsetX = 0
        offsetY = -BUFF_SPACING
    else
        relativeTo = frames[index - 1]
        relativePoint = "TOPRIGHT"
        offsetX = BUFF_SPACING
        offsetY = 0
    end
    frame:SetPoint("TOPLEFT", relativeTo, relativePoint, offsetX, offsetY)
    frames[index] = frame
    return frame
end

function TargetTextBuffs:CreateBuff(index)
    return self:CreateBuffBase(index, buffFrames, "TargetTextBuff" .. index, "TargetBuffFrameTemplate")
    -- TargetBuffButtonTemplate已经淘汰，换成TargetBuffFrameTemplate
end

function TargetTextBuffs:CreateDeBuff(index)
    return self:CreateBuffBase(index, debuffFrames, "TargetTexDeBuff" .. index, "TargetTextBuffsDebuffTemplate")
    -- TargetTextBuffsDebuffTemplate是自己定义的，它继承自TargetDebuffFrameTemplate
end

function TargetTextBuffs:UpdateBuffsBase(BuffFunc, frames, method)
    local index = 1
    local icon, count, duration, timeLeft, debuffType = BuffFunc(index)
    local anchorBuff
    while icon do
        local buff = frames[index] or self[method](self, index)
        buff:Show()
        if index % BUFFS_PER_ROW ==1 then
            anchorBuff = buff
        end
        buff.icon:SetTexture(icon)
        if count > 1 then
            buff.count:SetText(count)
            buff.count:Show()
        else
            buff.count:Hide()
        end
        if duration and duration > 0 then
            local startTime = GetTime() - (duration - timeLeft)
            buff.cooldown:SetCooldown(startTime, duration)
            buff.cooldown:Show()
        else
            buff.cooldown:Hide()
        end
        if buff.border then
            local color
            if debuffType then
                color = DebuffTypeColor[debuffType]
            else
                color = DebuffTypeColor["none"]
            end
            buff.border:SetVertexColor(color.r, color.g, color.b)
        end
        index = index + 1
        icon, count, duration, timeLeft, debuffType = BuffFunc(index)
    end
    for i = index, #frames do
        frames[i]:Hide()
    end
    return anchorBuff
end

function TargetTextBuffs:UpdateBuffs()
    return self:UpdateBuffsBase(function(index)
        local icon, count, duration, timeLeft = select(3, UnitBuff("target", index))
        -- UnitBuff() is an alias for UnitAura(unit, index, "HELPFUL"), returning only buffs.
        return icon, count, duration, timeLeft
    end, buffFrames, "CreateBuff")
end

function TargetTextBuffs:UpdateDeBuffs()
    return self:UpdateBuffsBase(function(index)
        local icon, count, debuffType, duration, timeLeft = select(3, UnitDeBuff("target", index))
        -- UnitDebuff() is an alias for UnitAura(unit, index, "HARMFUL"), returning only debuffs.
        return icon, count, duration, timeLeft,debuffType
    end, debuffFrames, "CreateDeBuff")
end

-- 1. name         string - The localized name of the aura, otherwise nil if there is no aura for the index.
-- 2. icon         number : FileID - The icon texture.
-- 3. count        number - The amount of stacks, otherwise 0.
-- 4. dispelType   string? - The locale-independent magic type of the aura: Curse, Disease, Magic, Poison, otherwise nil.
-- 5. duration     number - The full duration of the aura in seconds.
-- 6. expirationTime   number - Time the aura expires compared to GetTime(), e.g. to get the remaining duration: expirationtime - GetTime()

