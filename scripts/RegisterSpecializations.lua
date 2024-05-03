local function meetsRequirements(typeEntry, requirements)
    for _, spec in ipairs(requirements) do
        if not SpecializationUtil.hasSpecialization(spec, typeEntry.specializations) then
            return false
        end
    end

    return true
end

-- Registers a specialization with the provided name and adds it to the vehicle types which meet the given
-- requirements.
--
-- Requires that:
-- 1. "scripts/[specName].lua" exists, and
-- 2. the script contains a class with the same (case sensitive) name as the specialization.
local function register(specName, requirements)
    local fileName = Utils.getFilename("scripts/" .. specName .. ".lua", g_currentModDirectory)
    g_specializationManager:addSpecialization(specName, specName, fileName, '')

    for typeName, typeEntry in pairs(g_vehicleTypeManager.types) do
        if meetsRequirements(typeEntry, requirements) then
            g_vehicleTypeManager:addSpecialization(typeName, specName)
        end
    end
end


register("CombineAutoStop", { Drivable, Combine })
