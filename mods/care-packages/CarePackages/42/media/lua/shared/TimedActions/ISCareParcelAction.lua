require "TimedActions/ISBaseTimedAction"
local C = require "CarePackages"

ISCareParcelAction = ISBaseTimedAction:derive("ISCareParcelAction")

function ISCareParcelAction:isValid()
    return C.canHandle(self.character, self.item, self.operation) and C.revision(self.item) == self.revision
end

function ISCareParcelAction:start()
    self:setActionAnim("Craft")
    if not isServer() then
        self.item:setJobType(getText("IGUI_CarePackages_" .. self.operation))
    end
end

function ISCareParcelAction:update()
    if not isServer() then self.item:setJobDelta(self:getJobDelta()) end
end

function ISCareParcelAction:stop()
    if not isServer() then self.item:setJobDelta(0) end
    ISBaseTimedAction.stop(self)
end

function ISCareParcelAction:perform()
    self.item:setJobDelta(0)
    ISBaseTimedAction.perform(self)
end

function ISCareParcelAction:getDuration()
    return self.character:isTimedActionInstant() and 1 or 45
end

function ISCareParcelAction:complete()
    return C.change(self.character, self.item, self.operation, self.revision, self.toName, self.fromName, self.note)
end

-- The native network action serializes fields by their constructor parameter names.
function ISCareParcelAction:new(character, item, operation, revision, toName, fromName, note)
    local action = ISBaseTimedAction.new(self, character)
    action.item = item
    action.operation = operation
    action.revision = revision
    action.toName = toName
    action.fromName = fromName
    action.note = note
    action.stopOnWalk = true
    action.stopOnRun = true
    action.maxTime = action:getDuration()
    return action
end
