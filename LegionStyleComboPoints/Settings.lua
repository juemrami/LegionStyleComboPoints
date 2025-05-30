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
---@param config {defaults: table, widgets: savedVarWidgetDescription[]}
function SettingsModule:Initialize(config)
    -- only use per character for now
    local savedVarTable = _G[TOCNAME .. "DB"][PLAYER_NAME.."_"..PLAYER_REALM]
    assert(savedVarTable, "SavedVariables not found for " .. TOCNAME)
    settingsRegistry[savedVarTable] = settingsRegistry[savedVarTable] or {};
    local defaults = config.defaults
    ---@param rootWidgets savedVarWidgetDescription[]
    local function buildWidgets(rootWidgets, parentInitializer, enabledFunc)
        for _, description in ipairs(rootWidgets) do
            local savedVarKey = description.variable
            local settingID = TOCNAME..savedVarKey -- should be Unique to ALL addons
            local default = defaults[savedVarKey]
            local setting = Settings.RegisterAddOnSetting(
                category, settingID,
                savedVarKey, savedVarTable,
                type(default), description.displayStr, default
            )
            setting:SetValueChangedCallback(OnSettingChanged)
            settingsRegistry[savedVarTable][savedVarKey] = setting
            local initializer = Settings.CreateCheckbox(category, setting, description.tooltip)
            if parentInitializer and enabledFunc then
                -- Disable sub-options when parent is disabled
                initializer:SetParentInitializer(parentInitializer, enabledFunc)
            end
            if description.widgets then
                buildWidgets(description.widgets, initializer, function()
                    return setting:GetValue();
                end)
            end
        end
    end
    buildWidgets(config.widgets)
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
