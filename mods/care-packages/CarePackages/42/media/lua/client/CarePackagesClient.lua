require "ISUI/ISPanel"
require "ISUI/ISLabel"
require "ISUI/ISButton"
require "ISUI/ISTextEntryBox"
require "ISUI/ISInventoryPane"
require "ISUI/ISInventoryPage"
require "TimedActions/ISInventoryTransferAction"
require "TimedActions/ISCareParcelAction"
local C = require "CarePackages"

CareParcelForm = ISPanel:derive("CareParcelForm")
local active = {}
local prefix = "IGUI_CarePackages_"
local margin = 12
local font = UIFont.Small
local titleFont = UIFont.Medium

function CareParcelForm:addField(key, y, height, multiline)
    local label = ISLabel:new(margin, y, self.lineHeight, getText(prefix .. key), 1, 1, 1, 1, font, true)
    label:initialise()
    self:addChild(label)
    local field = ISTextEntryBox:new(self.values[key] or "", margin, y + self.lineHeight,
        self.width - margin * 2, height)
    field:initialise()
    field:instantiate()
    field:setEditable(self.editing)
    field:setMultipleLine(multiline)
    field:setMaxTextLength(multiline and C.noteLimit or C.nameLimit)
    self:addChild(field)
    return field
end

function CareParcelForm:createChildren()
    ISPanel.createChildren(self)
    local line = self.lineHeight
    self.toField = self:addField("to", margin + line + 6, line + 6, false)
    self.fromField = self:addField("from", margin + 3 * line + 12, line + 6, false)
    self.noteField = self:addField("note", margin + 5 * line + 24, 6 * line, true)
    local buttonY = self.height - margin - line - 6
    if self.editing then
        self.submit = ISButton:new(self.width - 232, buttonY, 132, line + 6,
            getText(prefix .. "seal"), self, CareParcelForm.onSubmit)
        self.submit:initialise()
        self:addChild(self.submit)
    end
    local close = ISButton:new(self.width - 92, buttonY, 80, line + 6,
        getText(self.editing and "UI_Cancel" or "UI_Ok"), self, CareParcelForm.close)
    close:initialise()
    self:addChild(close)
end

function CareParcelForm:render()
    ISPanel.render(self)
    self:drawText(getText(prefix .. (self.editing and "seal" or "read")), margin, margin, 1, 0.96, 0.86, 1, titleFont)
    if self.error then
        self:drawText(getText(prefix .. self.error), margin, self.noteField:getBottom() + 4, 1, 0.6, 0.5, 1, font)
    end
end

function CareParcelForm:close()
    self.toField:unfocus()
    self.fromField:unfocus()
    self.noteField:unfocus()
    self:removeFromUIManager()
    active[self.player:getPlayerNum()] = nil
end

function CareParcelForm:onSubmit()
    local toName = self.toField:getText()
    local fromName = self.fromField:getText()
    local note = self.noteField:getText()
    if not C.validate(toName, fromName, note) then
        self.error = "invalid"
    elseif not C.canHandle(self.player, self.item, "seal") then
        self.error = "status"
    else
        ISTimedActionQueue.add(ISCareParcelAction:new(self.player, self.item, "seal", C.revision(self.item), toName, fromName, note))
        self:close()
    end
end

function CareParcelForm.onParcel(item, player, editing)
    local playerNum = player:getPlayerNum()
    if active[playerNum] then active[playerNum]:close() end
    local width = 520
    local line = getTextManager():getFontHeight(font)
    local height = margin * 2 + 14 * line + 38
    local x = getPlayerScreenLeft(playerNum) + (getPlayerScreenWidth(playerNum) - width) / 2
    local y = getPlayerScreenTop(playerNum) + (getPlayerScreenHeight(playerNum) - height) / 2
    local form = ISPanel.new(CareParcelForm, math.max(0, x), math.max(0, y), width, height)
    local label = C.label(item)
    form.backgroundColor = { r = 0.08, g = 0.07, b = 0.06, a = 0.94 }
    form.borderColor = { r = 0.58, g = 0.52, b = 0.41, a = 1 }
    form.player = player
    form.item = item
    form.values = {
        to = label and label.toName or "",
        from = label and label.fromName or player:getDescriptor():getForename(),
        note = label and label.note or "",
    }
    form.editing = editing
    form.lineHeight = line
    form.moveWithMouse = true
    active[playerNum] = form
    form:initialise()
    form:addToUIManager()
    if editing then form.toField:focus() end
end

local function open(item, player)
    ISTimedActionQueue.add(ISCareParcelAction:new(player, item, "open", C.revision(item)))
end

local function menu(playerNum, context, selected)
    local items = ISInventoryPane.getActualItems(selected)
    local item = items[1]
    if #items ~= 1 or not C.isParcel(item) then return end
    local player = getSpecificPlayer(playerNum)
    if C.canHandle(player, item, "seal") then
        context:addOption(getText(prefix .. "seal"), item, CareParcelForm.onParcel, player, true)
    elseif C.canHandle(player, item, "open") then
        context:addOption(getText(prefix .. "open"), item, open, player)
    end
    if C.label(item) then
        context:addOption(getText(prefix .. "read"), item, CareParcelForm.onParcel, player, false)
    end
end

Events.OnFillInventoryObjectContextMenu.Add(menu)

-- The game also uses these container buttons to build its nearby recipe input list.
Events.OnRefreshInventoryWindowContainers.Add(function(page, phase)
    if phase ~= "buttonsAdded" then return end
    local removed = false
    for i = #page.backpacks, 1, -1 do
        local button = page.backpacks[i]
        if C.insideSeal(button.inventory) then
            page.containerButtonPanel:removeChild(button)
            table.insert(page.buttonPool, button)
            table.remove(page.backpacks, i)
            removed = true
        end
    end
    if removed then
        for i, button in ipairs(page.backpacks) do
            button:setY((i - 1) * page.buttonSize - 1)
        end
    end
end)

-- A transfer can already be queued when the parcel is sealed.
local validTransfer = ISInventoryTransferAction.isValid
function ISInventoryTransferAction:isValid()
    return not C.insideSeal(self.srcContainer) and not C.insideSeal(self.destContainer) and validTransfer(self)
end
