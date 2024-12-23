local TOCNAME, ns = ...
local addonFrame = CreateFrame("Frame", TOCNAME.."AddOn", UIParent)
-- accessible only by addon files
ns.privateHelloWorld = function() print("Hello, World!") end
-- accessible in global space
addonFrame.PublicHelloWorld = ns.privateHelloWorld
addonFrame:RegisterEvent("ADDON_LOADED")
addonFrame:SetScript("OnEvent", function(self, event, tocName)
    if tocName == TOCNAME then
        ns.privateHelloWorld()
    end
end)
