-- Test-only frontend probe. Production code and installed game files stay untouched.
require 'OptionScreens/ModSelector/ModInfoPanelDesc'
require 'OptionScreens/ModSelector/ModInfoPanelThumbnail'
local started, phase, nextSample, info = false, 0, 0, nil
local textures, ids, baseBytes = {}, {}, 0
local loadedHeap
local function sample(name)
    collectgarbage('collect')
    collectgarbage('collect')
    local heap=collectgarbage('count')
    print('PZ_TEST_MEMORY_SAMPLE '..string.format(
        '{"phase":"%s","heap_kib":%.2f,"base_texture_bytes":%d,"textures":%d}',name,heap,baseBytes,#textures))
    return heap
end
local function visit()
    local desc=ModInfoPanel.Desc:new(0,0,700)
    desc:initialise();desc:instantiate();desc:setModInfo(info)
    local thumbnails=ModInfoPanel.Thumbnail:new(0,0,700)
    thumbnails:initialise();thumbnails:instantiate();thumbnails:setModInfo(info)
end
Events.OnMainMenuEnter.Add(function()
    started=true
    nextSample=getTimestampMs()+10000
end)
Events.OnFETick.Add(function()
    if not started or phase==6 or getTimestampMs()<nextSample then return end
    local ok,message=pcall(function()
        if phase==0 then
            sample('menu_before_assets')
            info=assert(getModInfoByID(PZ_MEMORY_MOD_ID),'Missing mod metadata')
            visit()
            textures[1]=assert(getTexture(info:getIcon()),'Missing icon')
            for i=0,info:getPosterCount()-1 do textures[#textures+1]=assert(getTexture(info:getPoster(i)),'Missing poster') end
        elseif phase==1 then
            for i,tex in ipairs(textures) do
                assert(tex:isReady(),'Texture load did not finish')
                ids[i]=tex:getID()
                assert(ids[i]>0,'Native texture did not upload')
                local bytes=tex:getWidthHW()*tex:getHeightHW()*4
                baseBytes=baseBytes+bytes
                print('PZ_TEST_MEMORY_TEXTURE '..string.format('{"index":%d,"width":%d,"height":%d,"hardware_width":%d,"hardware_height":%d,"base_bytes":%d}',
                    i,tex:getWidth(),tex:getHeight(),tex:getWidthHW(),tex:getHeightHW(),bytes))
            end
            loadedHeap=sample('assets_loaded')
            -- ceiling: 100 setter cycles; add full selector navigation for a UI-specific reproduction.
            for i=1,100 do visit() end
        else
            for i,tex in ipairs(textures) do assert(tex:getID()==ids[i],'Repeated visits allocated a different texture') end
            assert(getTexture(info:getIcon())==textures[1],'Icon cache did not reuse the texture')
            for i=0,info:getPosterCount()-1 do assert(getTexture(info:getPoster(i))==textures[i+2],'Poster cache did not reuse the texture') end
            local heap=sample(phase==2 and 'after_100_panel_visits' or ('idle_'..(phase-2)))
            assert(heap-loadedHeap<16384,'Panel/idle retained heap growth exceeds 16 MiB')
            if phase==5 then print('PZ_TEST_MEMORY_PASS stable cached textures and retained heap budget') end
        end
        phase=phase+1
        nextSample=getTimestampMs()+5000
    end)
    if not ok then phase=6;print('PZ_TEST_FAIL memory probe '..tostring(message)) end
end)
