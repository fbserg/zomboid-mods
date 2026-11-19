local function prepareBow(_, item)
    if not item or not RadArchery or not RadArchery.BowArcheryScaling then return end
    if item:getModule() ~= "Base" or not RadArchery.BowArcheryScaling[item:getType()] then return end
    item:setMinSightRange(3)
    item:setMaxSightRange(14)
end

Events.OnEquipPrimary.Add(prepareBow)
Events.OnWeaponSwingHitPoint.Add(prepareBow)
Events.OnCreatePlayer.Add(function(_, player)
    prepareBow(player, player:getPrimaryHandItem())
end)
