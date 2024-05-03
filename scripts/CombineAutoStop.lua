CombineAutoStop = {}
CombineAutoStop.modName = g_currentModName
CombineAutoStop.modDir = g_currentModDirectory
CombineAutoStop.specName = "CombineAutoStop"
CombineAutoStop.specTableName = "spec_" .. CombineAutoStop.modName .. "." .. CombineAutoStop.specName

CombineAutoStop.debug = false

-- Console commands
addConsoleCommand(
    "casToggleDebug",
    "Toggle debug printing for Combine Auto Stop",
    "toggleDebug",
    CombineAutoStop)

function CombineAutoStop.toggleDebug()
    CombineAutoStop.debug = not CombineAutoStop.debug
    return "debug = " .. tostring(CombineAutoStop.debug)
end

function CombineAutoStop.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Drivable, specializations)
        and SpecializationUtil.hasSpecialization(Combine, specializations)
end

function CombineAutoStop.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", CombineAutoStop)
end

function CombineAutoStop.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "stop", CombineAutoStop.stop)
end

function CombineAutoStop:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType,
                                                    fillPositionData, appliedDelta)
    CombineAutoStop.debugPrint("Begin onFillUnitFillLevelChanged")
    CombineAutoStop.debugPrint({
        client = self.isClient,
        server = self.isServer
    })

    if not self.isServer then
        CombineAutoStop.debugPrint("End onFillUnitFillLevelChanged (not server)")
        return -- server side only please :]
    end

    -- Retrieve specializations
    local autoStop = self[CombineAutoStop.specTableName]
    local drivable = self.spec_drivable
    local combine = self.spec_combine

    if combine.fillUnitIndex ~= fillUnitIndex then
        CombineAutoStop.debugPrint("End onFillUnitFillLevelChanged (wrong fill unit changed)")
        return
    end

    if fillLevelDelta < 0 then
        CombineAutoStop.debugPrint("End onFillUnitFillLevelChanged (discharging)")
        return
    end

    local isCruising = drivable:getCruiseControlState() == Drivable.CRUISECONTROL_STATE_ACTIVE
    if not isCruising then
        CombineAutoStop.debugPrint("End onFillUnitFillLevelChanged (not cruising)")
        return
    end

    local fillPercentage = combine:getFillUnitFillLevel(fillUnitIndex) / combine:getFillUnitCapacity(fillUnitIndex)
    if fillPercentage < 1 then
        CombineAutoStop.debugPrint("End onFillUnitFillLevelChanged (not full)")
        return
    end

    autoStop:stop()
    CombineAutoStop.debugPrint("End onFillUnitFillLevelChanged (vehicle braking)")
end

function CombineAutoStop:stop()
    CombineAutoStop.debugPrint("Stopping vehicle")

    local combine = self.spec_combine
    local gps = self.spec_globalPositioningSystem

    -- Interop with stijnwop's Guidance Steering Mod
    if gps ~= nil then
        CombineAutoStop.debugPrint("Detected Guidance Steering")

        if gps:getHasGuidanceSystem() then
            CombineAutoStop.debugPrint("Guidance Steering is active, disengaging to stop vehicle")

            -- @stijnwop, if you're reading this, it'd be nice if you could provide a public interface
            -- to interface with the GPS :) I used your source code to find out this is what I need to do,
            -- but since its not in a public API you have every right to change how it works and break my mod.
            gps.lastInputValues.guidanceSteeringIsActive = false
            gps.guidanceSteeringIsActive = false
        end
    end

    combine:brakeToStop()
end

function CombineAutoStop.debugPrint(val)
    if not CombineAutoStop.debug then
        return
    end

    if type(val) == "table" then
        local str = ""
        for key, value in pairs(val) do
            str = str .. " " .. tostring(key) .. ": " .. tostring(value) .. ";"
        end

        CombineAutoStop.debugPrint(str)
    end

    if type(val) == "string" then
        printWarning("CombineAutoStop[Debug] " .. val)
    end
end

-- todo:
-- 1. interop with GPS to disable GPS before braking.
--    Required as GPS prevents brakeToStop from taking effect until GPS is disabled.
--    Helpful ref: https://github.com/stijnwop/guidanceSteering/blob/f82ef662b67cf20c50771f5c6f896cf92f077fc1/src/GuidanceSteering.lua#L412
