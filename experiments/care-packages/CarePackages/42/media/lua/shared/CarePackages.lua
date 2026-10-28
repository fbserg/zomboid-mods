CarePackages = {}
local C = CarePackages

-- Native object/item codec. The carrier is never inserted into the world.
function C.snapshot(parcel, wrapper)
    local body = IsoDeadBody.new(getCell())
    local container = ItemContainer.new()
    container:getItems():add(parcel)
    body:setContainer(container)
    wrapper:storeInByteData(body)
    assert(wrapper:getByteData(), 'Native parcel snapshot missing')
    return wrapper
end

function C.restore(wrapper, square)
    local body = assert(wrapper:loadCorpseFromByteData(square), 'Native parcel snapshot unreadable')
    local container = assert(body:getContainer(), 'Native parcel container missing')
    assert(container:getItems():size() == 1, 'Native parcel snapshot has wrong item count')
    return container:getItems():get(0)
end
