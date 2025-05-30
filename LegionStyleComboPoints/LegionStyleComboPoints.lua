local TOCNAME, ns = ...
local MAX_POINT_FRAMES = 6
local SettingsModule = ns.SettingsModule ---@type SettingsModule
local PLAYER_CLASS = UnitClassBase("player")
local PLAYER_NAME = UnitNameUnmodified("player")
local PLAYER_REALM = GetRealmName()
local addonFrame = CreateFrame("Frame", TOCNAME.."AddOn", UIParent)
local isClassicEra = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
local isMists = WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC
-- Mists adds a new mana bar below the player frame for druids in cat form.
local playerHasAlternateManaBar = isMists and PLAYER_CLASS == "DRUID"

--------------------------------------------------------------------------------
-- Setup for ComboPoints (the acutal points themslves)
--------------------------------------------------------------------------------

---@param parent Frame
---@param frameID string
local initComboPoint = function(parent, frameID)
    if parent[frameID] then return parent[frameID] end
    ---@class ComboPoint : Frame
    ---@field PointAnim AnimationGroup
    ---@field AnimIn AnimationGroup
    ---@field AnimOut AnimationGroup
    local pointFrame = CreateFrame("Frame", nil, parent)
    pointFrame.on = false
    pointFrame:SetSize(20, 21)
    pointFrame:SetParentKey(frameID)
    local pointBg = pointFrame:CreateTexture(nil, "BACKGROUND")
    pointBg:SetAtlas("ComboPoints-PointBg", false)
    pointBg:SetSize(20, 21)
    pointBg:SetPoint("CENTER")
    -- pointBg:SetPoint("CENTER", parent)
    pointFrame.PointOff = pointBg

    local actualPoint = pointFrame:CreateTexture(nil, "ARTWORK")
    actualPoint:SetAtlas("ComboPoints-ComboPoint", false)
    actualPoint:SetBlendMode("BLEND")
    actualPoint:SetAlpha(0)
    actualPoint:SetSize(20, 21)
    actualPoint:SetPoint("CENTER")
    pointFrame.Point = actualPoint

    local fxCircle = pointFrame:CreateTexture(nil, "ARTWORK")
    fxCircle:SetAtlas("ComboPoints-FX-Circle", true) -- uses atlas size
    fxCircle:SetBlendMode("BLEND")
    fxCircle:SetAlpha(0)
    -- fxCircle:SetSize(20, 21)
    fxCircle:SetPoint("CENTER")
    pointFrame.CircleBurst = fxCircle

    local fxStar = pointFrame:CreateTexture(nil, "OVERLAY")
    fxStar:SetAtlas("ComboPoints-FX-Star", true) -- uses atlas size
    fxStar:SetBlendMode("ADD")
    fxStar:SetAlpha(0)
    fxStar:SetPoint("CENTER")
    pointFrame.Star = fxStar

    -- Animations
    local pointAnim = pointFrame:CreateAnimationGroup()
    pointAnim:SetToFinalAlpha(true)
    local pointAlpha = pointAnim:CreateAnimation("Alpha")
    pointAlpha:SetDuration(0.25)
    pointAlpha:SetOrder(1)
    pointAlpha:SetFromAlpha(0)
    pointAlpha:SetToAlpha(1)
    pointAlpha:SetChildKey("Point")
    local pointScale = pointAnim:CreateAnimation("Scale")
    pointScale:SetSmoothing("OUT")
    pointScale:SetDuration(0.25)
    pointScale:SetOrder(1)
    pointScale:SetScaleFrom(0.8, 0.8)
    pointScale:SetScaleTo(1, 1)
    pointScale:SetChildKey("Point")
    pointAnim:SetParentKey("PointAnim")

    local animIn = pointFrame:CreateAnimationGroup()
    animIn:SetToFinalAlpha(true)
    local starScale = animIn:CreateAnimation("Scale")
    starScale:SetSmoothing("OUT")
    starScale:SetDuration(0.5)
    starScale:SetOrder(1)
    starScale:SetScaleFrom(0.25, 0.25)
    starScale:SetScaleTo(0.9, 0.9)
    starScale:SetChildKey("Star")
    local starRot = animIn:CreateAnimation("Rotation")
    starRot:SetSmoothing("OUT")
    starRot:SetDuration(0.8)
    starRot:SetOrder(1)
    starRot:SetDegrees(-60)
    starRot:SetChildKey("Star")
    local starAlpha = animIn:CreateAnimation("Alpha")
    starAlpha:SetSmoothing("IN")
    starAlpha:SetDuration(0.4)
    starAlpha:SetOrder(1)
    starAlpha:SetFromAlpha(0.75)
    starAlpha:SetToAlpha(0)
    starAlpha:SetStartDelay(0.5)
    starAlpha:SetChildKey("Star")
    local circleAlpha = animIn:CreateAnimation("Alpha")
    circleAlpha:SetDuration(0.1)
    circleAlpha:SetOrder(1)
    circleAlpha:SetFromAlpha(0)
    circleAlpha:SetToAlpha(1)
    circleAlpha:SetChildKey("CircleBurst")
    local circleScale = animIn:CreateAnimation("Scale")
    circleScale:SetSmoothing("OUT")
    circleScale:SetDuration(0.25)
    circleScale:SetOrder(1)
    circleScale:SetScaleFrom(1.25, 1.25)
    circleScale:SetScaleTo(0.75, 0.75)
    circleScale:SetChildKey("CircleBurst")
    local circleAlpha2 = animIn:CreateAnimation("Alpha")
    circleAlpha2:SetSmoothing("IN")
    circleAlpha2:SetDuration(0.25)
    circleAlpha2:SetOrder(1)
    circleAlpha2:SetFromAlpha(1)
    circleAlpha2:SetToAlpha(0)
    circleAlpha2:SetStartDelay(0.25)
    circleAlpha2:SetChildKey("CircleBurst")
    animIn:SetParentKey("AnimIn")

    local animOut = pointFrame:CreateAnimationGroup()
    animOut:SetToFinalAlpha(true)
    local circleAlpha = animOut:CreateAnimation("Alpha")
    circleAlpha:SetDuration(0.1)
    circleAlpha:SetOrder(1)
    circleAlpha:SetFromAlpha(0)
    circleAlpha:SetToAlpha(1)
    circleAlpha:SetChildKey("CircleBurst")
    local circleScale = animOut:CreateAnimation("Scale")
    circleScale:SetSmoothing("OUT")
    circleScale:SetDuration(0.4)
    circleScale:SetOrder(1)
    circleScale:SetScaleFrom(0.8, 0.8)
    circleScale:SetScaleTo(0.6, 0.6)
    circleScale:SetChildKey("CircleBurst")
    local circleAlpha2 = animOut:CreateAnimation("Alpha")
    circleAlpha2:SetSmoothing("IN")
    circleAlpha2:SetDuration(0.25)
    circleAlpha2:SetOrder(1)
    circleAlpha2:SetFromAlpha(1)
    circleAlpha2:SetToAlpha(0)
    circleAlpha2:SetStartDelay(0.25)
    circleAlpha2:SetChildKey("CircleBurst")
    animOut:SetParentKey("AnimOut")
    return pointFrame
end

-- Layout tweaks for different cp size frames.
-- Indexed by max "usable" combo points
local layoutByMaxPoints = {
    [5] = {
        ["width"] = 20,
        ["height"] = 21,
        ["xOffs"] = 1,
    },
    [6] = {
        ["width"] = 18,
        ["height"] = 19,
        ["xOffs"] = -1,
    },
};

--- Correctly anchors a child Point on the ComboPointBar based on the max points.
---@param maxPoints number max points that should be shown
---@param currentPoint ComboPoint
---@param prevPoint ComboPoint?
local function updateComboPointLayout(maxPoints, currentPoint, prevPoint)
    local layout = layoutByMaxPoints[maxPoints];

    currentPoint:SetSize(layout.width, layout.height);
    currentPoint.PointOff:SetSize(layout.width, layout.height);
    currentPoint.Point:SetSize(layout.width, layout.height);

    if (prevPoint) then
        currentPoint:SetPoint("LEFT", prevPoint, "RIGHT", layout.xOffs, 0);
    end
end
--------------------------------------------------------------------------------
-- Setup for ComboPointBar (parent to the combo points)
--------------------------------------------------------------------------------

-- todo, moved to saved var to persist between sessions
local sessionDraggableState = false 
local updateDragMoveHandlers = function(self, makeDraggable)
    sessionDraggableState = makeDraggable
    if makeDraggable then
        self:SetMovable(true)
        self:RegisterForDrag("LeftButton")
        self:SetScript("OnDragStart", function(self)
            self:StartMoving()
        end)
        self:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
        end)
    else
        self:SetMovable(false)
        self:RegisterForDrag()
        self:SetScript("OnDragStart", nil)
        self:SetScript("OnDragStop", nil)
    end
end
local updateTooltipHandlers = function(self, enableTooltip, showClickInstructions)
    if enableTooltip then
        self:SetScript("OnEnter", function(self)
            GameTooltip_SetDefaultAnchor(GameTooltip, self)
            GameTooltip_SetTitle(GameTooltip, C_AddOns.GetAddOnMetadata(TOCNAME, "X-Short-Name"), NORMAL_FONT_COLOR)
            if showClickInstructions then 
                GameTooltip_AddInstructionLine(GameTooltip, UNIT_POPUP_RIGHT_CLICK or "<Right click for Frame Settings")
            end
            GameTooltip:Show()
        end)
        self:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
    else
        self:SetScript("OnEnter", nil)
        self:SetScript("OnLeave", nil)
    end
end
local updateContextMenuHandlers = function (self, enableMenu)
    if enableMenu then
        local menuGenerator = function(owner, rootDescription)
            ---@cast rootDescription RootMenuDescriptionProxy
            rootDescription:CreateTitle("Combo Point Bar")
            do
                local setting = SettingsModule.GetSavedVarSettingObject(
                    _G[TOCNAME.."DB"][PLAYER_NAME.."_"..PLAYER_REALM], "showBackground"
                );
                local isSelected = function() return setting:GetValue() end
                local onSelect = function() setting:SetValue(not setting:GetValue()) end
                rootDescription:CreateCheckbox("Show Background", isSelected, onSelect)
            end
            do 
                ---@return boolean true if the frame is locked (aka not draggable)
                local isSelected = function() return not sessionDraggableState end
                local onSelect = function()
                    sessionDraggableState = not sessionDraggableState
                    updateDragMoveHandlers(self, sessionDraggableState)
                end
                rootDescription:CreateCheckbox(LOCK_FRAME, isSelected, onSelect)
            end
        end
    self:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
          MenuUtil.CreateContextMenu(self, menuGenerator)
        end
    end)
    else
        self:SetScript("OnEnter", nil)
        self:SetScript("OnLeave", nil)
        self:SetScript("OnMouseDown", nil)
    end
end

---@param self ComboPointBarMixin
local connectToPlayerFrame = function(self)
    local xOffs, yOffs = 50, 38
    if playerHasAlternateManaBar then -- slightly adjust the position downward
        xOffs, yOffs = 52, 24
    end
    self:SetSize(126, 18)
    self:SetParent(PlayerFrame)
    self:SetPoint("TOP", PlayerFrame, "BOTTOM", xOffs, yOffs)
    self:SetFrameLevel(PlayerFrame:GetFrameLevel() + 2)
end

---@class ComboPointBarMixin: Frame
local ComboPointBarMixin = {};

function ComboPointBarMixin:OnLoad()
    self:SetScript("OnEvent", self.OnEvent)
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    if PLAYER_CLASS == "DRUID" then
        -- see event handler for other registered druid events
        self:RegisterUnitEvent("UNIT_DISPLAYPOWER", "player")
    else -- Rogue
        self:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
        self:RegisterUnitEvent("UNIT_MAXPOWER", "player")
        if isClassicEra then
            self:RegisterUnitEvent("UNIT_TARGET", "player")
        end
    end
    self:ConnectToPlayerFrame()
    self.BackGround = self:CreateTexture(nil, "OVERLAY")
    self.BackGround:SetAtlas("ComboPoints-AllPointsBG", true)
    self.BackGround:SetPoint("TOPLEFT")
    self:InitilizeComboPoints()
    addonFrame.ComboPointBar = self
end
function ComboPointBarMixin:OnEvent(event, ...)
    if event == "UNIT_POWER_UPDATE" and select(2, ...) == "COMBO_POINTS" then
        self:UpdateComboPoints()
    elseif event == "UNIT_TARGET" then self:UpdateComboPoints()
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- execute the UNIT_DISPLAYPOWER handler to setup the correct events for druid
        if PLAYER_CLASS == "DRUID" then self:OnEvent("UNIT_DISPLAYPOWER") end
        -- UnitPowerMax returns 0 for combopoints untill the PLAYER ENTERING WORLD event
        self.maxPlayerComboPoints = UnitPowerMax("player", Enum.PowerType.ComboPoints, true)
        self:LayoutComboPoints()
        self:UpdateComboPoints()
    elseif event == "UNIT_DISPLAYPOWER" then -- Setup druid events only for cat form
        -- UnitPowerType returns PowerType.Mana for druids, even in catform, untill PLAYER_ENTERING_WORLD event
        local powerType = UnitPowerType("player") 
        local useComboPoints = powerType == Enum.PowerType.Energy
        local registerFunc = useComboPoints and self.RegisterUnitEvent or self.UnregisterEvent
        self:SetShown(useComboPoints)
        registerFunc(self, "UNIT_POWER_UPDATE", "player")
        registerFunc(self, "UNIT_MAXPOWER", "player")
        if isClassicEra then registerFunc(self, "UNIT_TARGET", "player") end
    end
end
function ComboPointBarMixin:LayoutComboPoints()
    for i = 1, self.maxPlayerComboPoints do
        updateComboPointLayout(
            self.maxPlayerComboPoints,
            self.ComboPoints[i], 
            self.ComboPoints[i - 1]
        )
        self.ComboPoints[i]:SetShown(true)
    end

end
function ComboPointBarMixin:InitilizeComboPoints()
    self.ComboPoints = {} ---@type ComboPoint[]
    for i = 1, MAX_POINT_FRAMES do
        local frameKey = "ComboPoint" .. i
        local pointFrame = initComboPoint(self, frameKey)
        if i == 1 then
            pointFrame:SetPoint("TOPLEFT", 11, -2)
        else
            pointFrame:SetPoint("LEFT", self.ComboPoints[i - 1], "RIGHT", 1, 0)
        end
        pointFrame:SetShown(false)
        self.ComboPoints[i] = pointFrame
    end
end
function ComboPointBarMixin:UpdateComboPoints(forcePoints)
    local currentPoints = forcePoints and forcePoints or UnitPower("player", Enum.PowerType.ComboPoints)
    for i = 1, min(currentPoints, self.maxPlayerComboPoints) do
        local point = self.ComboPoints[i]
        if (not point.on) then
            point.on = true;
            point.AnimIn:Play();
            if (point.PointAnim) then
                point.PointAnim:Play();
            end
        end
    end
    for i = currentPoints + 1, self.maxPlayerComboPoints do
        local point = self.ComboPoints[i]
        if (point.on) then
            point.on = false;
            if (point.PointAnim) then
                point.PointAnim:Play(true);
            end
            point.AnimIn:Stop();
            point.AnimOut:Play();
        end
    end
end
function ComboPointBarMixin:SetBackgroundShown(show)
    self.BackGround:SetShown(show)
    for _, point in ipairs(self.ComboPoints) do
        point.PointOff:SetAtlas(show and "ComboPoints-PointBg" or "ClassOverlay-ComboPoint-Off", false)
        point.PointOff:SetAlpha(show and 1 or 0.9)
        point.PointOff:SetScale(show and 1 or 0.75)
    end
end
function ComboPointBarMixin:ConnectToPlayerFrame() -- overridable by frame addons
    self:ClearAllPoints()
    connectToPlayerFrame(self)
end
function ComboPointBarMixin:Detach(xOffs, yOffs)
    -- for now dont actually unparent it, just remove the anchors to PlayerFrame
    if not (xOffs and yOffs) then -- use its position when at playeframe, offset by a couple pixel to make obvious to user
        xOffs = self:GetLeft() + 15
        yOffs = self:GetTop() - 15
    else
        xOffs = xOffs or 0
        yOffs = yOffs or 0
    end
    self:ClearAllPoints()
    self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", xOffs, yOffs)
end
--------------------------------------------------------------------------------
-- Addon load
--------------------------------------------------------------------------------

addonFrame:RegisterEvent("ADDON_LOADED")
addonFrame:SetScript("OnEvent", function(self, event, tocName)
    if tocName == TOCNAME then
        if PLAYER_CLASS ~= "ROGUE" and PLAYER_CLASS ~= "DRUID" then return end
        local SavedVarsID = TOCNAME.."DB"
        local characterKey = ('%s_%s'):format(PLAYER_NAME, PLAYER_REALM)
        if not _G[SavedVarsID] then _G[SavedVarsID] = {} end
        if not _G[SavedVarsID][characterKey] then _G[SavedVarsID][characterKey] = {} end
        local charSavedVars = _G[SavedVarsID][characterKey]
        ---@class savedVarWidgetDescription
        ---@field variable string the saved variable name
        ---@field displayStr string the display string for the setting
        ---@field tooltip string? the tooltip for the setting
        ---@field widgets savedVarWidgetDescription[]? sub widgets for this setting
        SettingsModule:Initialize({
            defaults = {
                showBackground = not playerHasAlternateManaBar,
                enableDetachedMode = false,
                enableDetachedFrameTooltip = true,
                enableDetachedFrameRightClickMenu = true,
            },
            widgets = {
                {
                    variable = "showBackground",
                    displayStr = "Show Background Texture",
                    tooltip = "Disable to remove the background from the combo points bar.",
                },
                {
                    variable = "enableDetachedMode",
                    displayStr = "Enabled Detached Mode",
                    tooltip = "Detach the combo points bar from the player frame. Right click and unlock the bar to move it.",
                    widgets = {
                        {
                            variable = "enableDetachedFrameTooltip",
                            displayStr = "Enable Frame Tooltip",
                            tooltip = "Show a tooltip when hovering over the detached combo points bar.",
                        },
                        {
                            variable = "enableDetachedFrameRightClickMenu",
                            displayStr = "Enable Right-click Menu",
                            tooltip = "Enables a settings quick menu when right clicking the detached combo points bar.",
                        },
                    },
                },
            }
        })
        local ComboPointsBar = CreateFrame("Frame", TOCNAME.."Bar", PlayerFrame)
        ComboPointsBar = Mixin(ComboPointsBar, ComboPointBarMixin)
        ComboPointsBar:OnLoad()
        ComboPointsBar:Show()

        -- hook to settings updates
        local execOnRegister = true -- fire once initially to sync frames to settings
        SettingsModule.AddSavedVarUpdateHook(charSavedVars, "showBackground", function(setting, value)
            ComboPointsBar:SetBackgroundShown(value)
        end, execOnRegister)
        SettingsModule.AddSavedVarUpdateHook(charSavedVars, "enableDetachedMode", function(setting, isDetached)
            if isDetached then
                ComboPointsBar:Detach(charSavedVars.detachedXOffset, charSavedVars.detachedYOffset)
                ComboPointsBar:EnableMouse(charSavedVars.enableDetachedFrameRightClickMenu or charSavedVars.enableDetachedFrameTooltip)
                updateContextMenuHandlers(ComboPointsBar, charSavedVars.enableDetachedFrameRightClickMenu)
                updateTooltipHandlers(ComboPointsBar, charSavedVars.enableDetachedFrameTooltip, charSavedVars.enableDetachedFrameRightClickMenu)
            else
                ComboPointsBar:EnableMouse(false)
                updateContextMenuHandlers(ComboPointsBar, false)
                updateTooltipHandlers(ComboPointsBar, false)
                ComboPointsBar:ConnectToPlayerFrame()
            end
        end, execOnRegister)
        hooksecurefunc(ComboPointsBar, "StopMovingOrSizing", function()
            if not charSavedVars.enableDetachedMode then return end
            charSavedVars.detachedXOffset = ComboPointsBar:GetLeft()
            charSavedVars.detachedYOffset = ComboPointsBar:GetTop()
        end)
        SettingsModule.AddSavedVarUpdateHook(charSavedVars, "enableDetachedFrameTooltip", function(setting, value)
            updateTooltipHandlers(ComboPointsBar, value, charSavedVars.enableDetachedFrameRightClickMenu)
        end, not execOnRegister)
        SettingsModule.AddSavedVarUpdateHook(charSavedVars, "enableDetachedFrameRightClickMenu", function(setting, value)
            updateContextMenuHandlers(ComboPointsBar, value)
            if charSavedVars.enableDetachedFrameTooltip then -- toggle right click instruction text on tooltip
                updateTooltipHandlers(ComboPointsBar, true, value)
            end
        end, not execOnRegister)
    end
end)