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
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", CombineAutoStop)
end

function CombineAutoStop:onUpdate(dt)
    CombineAutoStop.debugPrint("Begin Update")
    CombineAutoStop.debugPrint({
        client = self.isClient,
        server = self.isServer
    })

    if not self.isServer then
        CombineAutoStop.debugPrint("End Update (not server)")
        return -- server side only please :]
    end

    -- Retrieve specializations
    local autoStop = self[CombineAutoStop.specTableName]
    local drivable = self.spec_drivable
    local combine = self.spec_combine

    local fillUnitIndex = combine.fillUnitIndex
    local fillPercentage = combine:getFillUnitFillLevel(fillUnitIndex) / combine:getFillUnitCapacity(fillUnitIndex)

    local isCruising = drivable:getCruiseControlState() == Drivable.CRUISECONTROL_STATE_ACTIVE
    local isFull = fillPercentage >= 1

    -- We monitor whether or not the combine was threshing so that cruise may be used
    -- while full (e.g. to drive to a truck). The only time we want to stop the vehicle
    -- when it is cruising and full is right after it becomes full while cruising.
    local wasThreshing = Utils.getNoNil(autoStop.wasThreshing, false)
    local isThreshing = combine:getIsTurnedOn()
    autoStop.wasThreshing = isThreshing

    local threshingStopped = wasThreshing and not isThreshing

    CombineAutoStop.debugPrint({
        cruising = isCruising,
        full = isFull,
        isThreshing = isThreshing,
        wasThreshing = wasThreshing,
        threshingStopped = threshingStopped
    })

    if isCruising and isFull and threshingStopped then
        combine:brakeToStop()
        CombineAutoStop.debugPrint("Braking")
    end

    CombineAutoStop.debugPrint("End Update (No action required/action taken)")
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
-- 2. unregister the event listener when nobody is driving the vehicle.
