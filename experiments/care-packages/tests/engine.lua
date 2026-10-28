local X,Y=10628,10658
local started,done=false,false
Events.OnServerStarted.Add(function() started=true end)
Events.OnTick.Add(function()
    if not started or done or not farmTestKeepLoaded then return end
    farmTestKeepLoaded(X,Y)
    local square=getCell():getGridSquare(X,Y,0)
    if not square then return end
    done=true
    local ok,message=pcall(function()
        local marker=ModData.getOrCreate('CareParcelProbe')
        local stash
        for i=0,square:getObjects():size()-1 do
            local obj=square:getObjects():get(i)
            if obj:getName()=='CareParcelProbe' then stash=obj:getContainer() end
        end
        if not marker.saved then
            local bag=instanceItem('Base.Bag_Schoolbag')
            bag:getModData().personal={name='Alice',message='Come home safe'}
            local food=bag:getInventory():AddItem('Base.Apple')
            food:setAge(1.5); food:setHeat(0.5)
            local gun=bag:getInventory():AddItem('Base.Pistol')
            gun:setCondition(4); gun:setCurrentAmmoCount(7)
            local note=bag:getInventory():AddItem('Base.Notebook')
            note:addPage(1,'A note that must survive')
            local jacket=bag:getInventory():AddItem('Base.Jacket_Leather')
            jacket:setCondition(3); jacket:getModData().custom='mod-owned data'
            local wrapper=instanceItem('Base.Book')
            CarePackages.snapshot(bag,wrapper)
            local copy=CarePackages.restore(wrapper,square)
            assert(copy:getInventory():getItems():size()==4,'Contents lost')
            assert(copy:getModData().personal.message=='Come home safe','Bag data lost')
            local items=copy:getInventory()
            assert(items:getFirstType('Base.Pistol'):getCurrentAmmoCount()==7,'Ammo lost')
            assert(items:getFirstType('Base.Pistol'):getCondition()==4,'Repair state lost')
            assert(items:getFirstType('Base.Notebook'):seePage(1)=='A note that must survive','Text lost')
            assert(items:getFirstType('Base.Jacket_Leather'):getModData().custom=='mod-owned data','Custom data lost')
            assert(math.abs(items:getFirstType('Base.Apple'):getAge()-1.5)<0.001,'Food age changed')
            print('PZ_TEST_PASS native codec preserves whole bag, ammo, condition, text and custom data')
            local object=IsoObject.new(square,'carpentry_01_16','CareParcelProbe')
            stash=ItemContainer.new('crate',square,object)
            object:setContainer(stash); square:AddTileObject(object)
            stash:AddItem(wrapper)
            marker.saved=true; marker.age=getGameTime():getWorldAgeHours()
        else
            local wrapper=assert(stash,'Saved stash missing'):getItems():get(0)
            local copy=CarePackages.restore(wrapper,square)
            assert(copy:getInventory():getItems():size()==4,'Restart lost contents')
            assert(copy:getInventory():getFirstType('Base.Notebook'):seePage(1)=='A note that must survive','Restart lost text')
            print('PZ_TEST_RESTART_PASS native opaque bytes survive full game save and restart')
        end
    end)
    print(ok and 'PZ_TEST_ENGINE_PASS' or ('PZ_TEST_FAIL '..tostring(message)))
end)
