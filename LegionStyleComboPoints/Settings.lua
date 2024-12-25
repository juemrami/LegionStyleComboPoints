local TOCNAME, ns = ...
local PLAYER_NAME = UnitNameUnmodified("player")
local PLAYER_REALM = GetRealmName()
local category = Settings.RegisterVerticalLayoutCategory("Legion ComboPoints Bar")
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
    do 
        local name = "Show Background Texture"
        local variable = TOCNAME.."showBackground" -- should be Unique to ALL addons
        local savedVarKey = "showBackground"
        local default = true
        local tooltip = "Disable to remove the background from the combo points bar."
        ---@type AddonSettingMixin
        local setting = Settings.RegisterAddOnSetting(category, variable, savedVarKey, savedVars, type(default), name, default)
        setting:SetValueChangedCallback(OnSettingChanged)
        settingsRegistry[savedVars] = settingsRegistry[savedVars] or {};
        settingsRegistry[savedVars][savedVarKey] = setting
        Settings.CreateCheckbox(category, setting, tooltip)
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
ns.SettingsModule = SettingsModule;

--------------------------------------------------------------------------------
-- Custom setting frame tempalte setu
--------------------------------------------------------------------------------
