local TOCNAME, ns = ...
local PLAYER_NAME = UnitNameUnmodified("player")
local PLAYER_REALM = GetRealmName()
local category = Settings.RegisterVerticalLayoutCategory(C_AddOns.GetAddOnMetadata(TOCNAME, "X-Short-Name"));
local settingsRegistry = {}; ---@type {[table]: {[string]: AddonSettingMixin}}
local settingCallbacks = {}; ---@type {[AddonSettingMixin]: {[function]: boolean?}}
local function OnSettingChanged(setting, value)
	-- This callback will be invoked whenever a setting is modified.
	-- print("Setting changed:", setting:GetVariable(), value)
    if settingCallbacks[setting] then
        for callback, _ in pairs(settingCallbacks[setting]) do
            callback(setting, value)
        end
    end
end
---@class SettingsModule
local SettingsModule = {};
function SettingsModule:OnLoad()
    -- only use per character for now
    local savedVars = _G[TOCNAME .. "DB"][PLAYER_NAME.."_"..PLAYER_REALM]
    assert(savedVars, "SavedVariables not found for " .. TOCNAME)
    settingsRegistry[savedVars] = settingsRegistry[savedVars] or {};
    do 
        local name = "Show Background Texture"
        local variable = TOCNAME.."showBackground" -- should be Unique to ALL addons
        local savedVarKey = "showBackground"
        local default = true
        local tooltip = "Disable to remove the background from the combo points bar."
        ---@type AddonSettingMixin
        local setting = Settings.RegisterAddOnSetting(category, variable, savedVarKey, savedVars, type(default), name, default)
        setting:SetValueChangedCallback(OnSettingChanged)
        settingsRegistry[savedVars][savedVarKey] = setting
        Settings.CreateCheckbox(category, setting, tooltip)
    end
    do
        local name = "Enabled Detached Mode"
        local variable = TOCNAME.."enableDetachedMode"
        local default = false
        local savedVarKey = "enableDetachedMode"
        local tooltip = "Detach the combo points bar from the player frame. Right click and unlock the bar to move it."
        local setting = Settings.RegisterAddOnSetting(category, variable, savedVarKey, savedVars, type(default), name, default)
        setting:SetValueChangedCallback(OnSettingChanged)
        settingsRegistry[savedVars][savedVarKey] = setting
        local detachSettingInitializer = Settings.CreateCheckbox(category, setting, tooltip)
        local isSubOptionEnabled = function()
            return setting:GetValue()
        end
        do -- Enable Tooltip (default: true)
            local name = "Enable Frame Tooltip"
            local variable = TOCNAME.."enableDetachedFrameTooltip"
            local default = true
            local savedVarKey = "enableDetachedFrameTooltip"
            local tooltip = "Show a tooltip when hovering over the detached combo points bar."
            local setting = Settings.RegisterAddOnSetting(category, variable, savedVarKey, savedVars, type(default), name, default)
            setting:SetValueChangedCallback(OnSettingChanged)
            settingsRegistry[savedVars][savedVarKey] = setting
            local initializer = Settings.CreateCheckbox(category, setting, tooltip)
            initializer:SetParentInitializer(detachSettingInitializer, isSubOptionEnabled)
        end
        do -- Enable rightclick menu (default: true)
            local name = "Enable Right-click Menu"
            local variable = TOCNAME.."enableDetachedFrameRightClickMenu"
            local default = true
            local savedVarKey = "enableDetachedFrameRightClickMenu"
            local tooltip = "Enables a settings quick menu when right clicking the detached combo points bar."
            local setting = Settings.RegisterAddOnSetting(category, variable, savedVarKey, savedVars, type(default), name, default)
            setting:SetValueChangedCallback(OnSettingChanged)
            settingsRegistry[savedVars][savedVarKey] = setting
            local initializer = Settings.CreateCheckbox(category, setting, tooltip)
            initializer:SetParentInitializer(detachSettingInitializer, isSubOptionEnabled)
        end
    end
    Settings.RegisterAddOnCategory(category)
end

---@param table table
---@param variable string
---@param callback fun(setting: AddonSettingMixin, value: any)
---@param fire boolean? fire callback on registration
function SettingsModule.AddSavedVarUpdateHook(table, variable, callback, fire)
    local setting = settingsRegistry[table][variable]
    assert(setting, "Setting not found for passed table", variable, table)
    settingCallbacks[setting] = settingCallbacks[setting] or {}
    settingCallbacks[setting][callback] = true
    if fire then
        callback(setting, setting:GetValue())
    end
end

function SettingsModule.GetSavedVarSettingObject(table, variable)
    return settingsRegistry[table][variable]
end
ns.SettingsModule = SettingsModule;

--------------------------------------------------------------------------------
-- Custom setting frame tempalte setu
--------------------------------------------------------------------------------
