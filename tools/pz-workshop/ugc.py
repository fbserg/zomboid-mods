#!/usr/bin/env python3
"""Gallery and download verification through the installed Steamworks library. No browser credentials."""
from pathlib import Path
import argparse
import ctypes as C
import json
import os
import re
import time
import urllib.request

GAME = Path.home()/'Library/Application Support/Steam/steamapps/common/ProjectZomboid/Project Zomboid.app/Contents/Java'
OWNER = 76561198033173095
U64, U32, PTR, BOOL = C.c_uint64, C.c_uint32, C.c_void_p, C.c_bool


class QueryResult(C.Structure):
    _layout_ = 'ms'
    _pack_ = 4  # Steamworks callback packing on macOS, from Valve steamclientpublic.h.
    _fields_ = [('handle',U64),('result',C.c_int),('returned',U32),('total',U32),('cached',BOOL),('cursor',C.c_char*256)]


class UpdateResult(C.Structure):
    _layout_ = 'ms'
    _pack_ = 4
    _fields_ = [('result',C.c_int),('legal',BOOL),('item',U64)]


class Steam:
    def __init__(self) -> None:
        os.environ['SteamAppId']='108600'
        self.lib=C.CDLL(str(GAME/'libsteam_api.dylib'))
        self.init=self.bind('InitSafe',BOOL,[])
        self.shutdown=self.bind('Shutdown',None,[])
        self.callbacks=self.bind('RunCallbacks',None,[])
        assert self.init(), 'Steam client session unavailable'
        self.ugc=self.bind('SteamUGC_v021',PTR,[])()
        self.utils=self.bind('SteamUtils_v010',PTR,[])()
        user=self.bind('SteamUser_v023',PTR,[])()
        assert self.ugc and self.utils and user, 'Installed Steamworks interfaces unavailable'
        owner=self.bind('ISteamUser_GetSteamID',U64,[PTR])(user)
        assert owner==OWNER, f'Unexpected Steam owner {owner}'
        print(f'STEAM_ACCOUNT {owner}',flush=True)

    def bind(self,name: str,result: object,args: list) -> object:
        function=getattr(self.lib,'SteamAPI_'+name)
        function.restype=result;function.argtypes=args
        return function

    def wait(self,call: int,result: C.Structure,callback: int) -> None:
        assert call, 'Invalid API call'
        completed=self.bind('ISteamUtils_IsAPICallCompleted',BOOL,[PTR,U64,C.POINTER(BOOL)])
        fetch=self.bind('ISteamUtils_GetAPICallResult',BOOL,[PTR,U64,PTR,C.c_int,C.c_int,C.POINTER(BOOL)])
        failed=BOOL()
        deadline=time.monotonic()+180
        while not completed(self.utils,call,C.byref(failed)):
            assert time.monotonic()<deadline, 'Steam API call timed out; query before any retry'
            self.callbacks();time.sleep(0.1)
        assert not failed.value, 'Steam API call failed'
        assert fetch(self.utils,call,C.byref(result),C.sizeof(result),callback,C.byref(failed)), 'Cannot read Steam result'
        assert not failed.value and result.result==1, f'Steam result {result.result}'

    def previews(self,item: int) -> list[dict]:
        ids=(U64*1)(item)
        query=self.bind('ISteamUGC_CreateQueryUGCDetailsRequest',U64,[PTR,C.POINTER(U64),U32])(self.ugc,ids,1)
        assert query!=2**64-1
        release=self.bind('ISteamUGC_ReleaseQueryUGCRequest',BOOL,[PTR,U64])
        try:
            assert self.bind('ISteamUGC_SetAllowCachedResponse',BOOL,[PTR,U64,U32])(self.ugc,query,0)
            assert self.bind('ISteamUGC_SetReturnAdditionalPreviews',BOOL,[PTR,U64,BOOL])(self.ugc,query,True)
            call=self.bind('ISteamUGC_SendQueryUGCRequest',U64,[PTR,U64])(self.ugc,query)
            result=QueryResult();self.wait(call,result,3401)
            assert result.returned==1, 'Workshop item not returned'
            count=self.bind('ISteamUGC_GetQueryUGCNumAdditionalPreviews',U32,[PTR,U64,U32])(self.ugc,query,0)
            get=self.bind('ISteamUGC_GetQueryUGCAdditionalPreview',BOOL,[PTR,U64,U32,U32,PTR,U32,PTR,U32,C.POINTER(C.c_int)])
            previews=[]
            for index in range(count):
                url=C.create_string_buffer(4096);name=C.create_string_buffer(1024);kind=C.c_int()
                assert get(self.ugc,query,0,index,url,len(url),name,len(name),C.byref(kind))
                previews.append({'file':name.value.decode(),'url':url.value.decode(),'type':kind.value})
            return previews
        finally:
            assert release(self.ugc,query)

    def quota(self) -> tuple[int,int]:
        storage=self.bind('SteamRemoteStorage_v016',PTR,[])()
        total=U64();available=U64()
        assert self.bind('ISteamRemoteStorage_GetQuota',BOOL,[PTR,C.POINTER(U64),C.POINTER(U64)])(storage,C.byref(total),C.byref(available))
        return total.value,available.value

    def gallery(self,item: int,images: list[Path]) -> None:
        assert images and len({p.name for p in images})==len(images)
        for image in images:
            assert image.is_file() and image.stat().st_size<1_000_000, image
        current=self.previews(item)
        if [p['file'] for p in current]==[p.name for p in images]:
            assert all(urllib.request.urlopen(preview['url'],timeout=30).read()==image.read_bytes()
                       for preview,image in zip(current,images)), 'Gallery filenames match but image bytes differ. Refuse replacement.'
            print('GALLERY_ALREADY_SET bytes verified');return
        assert not current, 'Gallery already has images. Refuse duplication or replacement.'
        total,available=self.quota()
        required=sum(p.stat().st_size for p in images)
        assert required<=available, f'Steam Cloud quota: batch needs {required} bytes, available {available}/{total}. Export smaller gallery files before retrying.'
        handle=self.bind('ISteamUGC_StartItemUpdate',U64,[PTR,U32,U64])(self.ugc,108600,item)
        assert handle!=2**64-1
        add=self.bind('ISteamUGC_AddItemPreviewFile',BOOL,[PTR,U64,C.c_char_p,C.c_int])
        for image in images:
            assert add(self.ugc,handle,os.fsencode(image),0), image
        call=self.bind('ISteamUGC_SubmitItemUpdate',U64,[PTR,U64,C.c_char_p])(self.ugc,handle,b'Add illustration and native gameplay gallery.')
        result=UpdateResult();self.wait(call,result,3404)
        assert not result.legal and result.item==item, 'Workshop agreement or unexpected item'
        actual=self.previews(item)
        assert [p['file'] for p in actual]==[p.name for p in images], actual
        print('GALLERY_PUBLISHED '+json.dumps(actual),flush=True)

    def download(self,item: int) -> Path:
        # Downloads owner content for release verification. Does not alter subscriptions.
        assert self.bind('ISteamUGC_DownloadItem',BOOL,[PTR,U64,BOOL])(self.ugc,item,True), 'Download rejected'
        state=self.bind('ISteamUGC_GetItemState',U32,[PTR,U64])
        deadline=time.monotonic()+180
        while True:
            self.callbacks();value=state(self.ugc,item)
            if value&4 and not value&(8|16|32): break
            assert time.monotonic()<deadline, f'Download timed out, state={value}'
            time.sleep(0.2)
        folder=C.create_string_buffer(4096);size=U64();stamp=U32()
        assert self.bind('ISteamUGC_GetItemInstallInfo',BOOL,[PTR,U64,C.POINTER(U64),PTR,U32,C.POINTER(U32)])(self.ugc,item,C.byref(size),folder,len(folder),C.byref(stamp))
        path=Path(os.fsdecode(folder.value));print('DOWNLOADED '+str(path),flush=True)
        return path


def main() -> None:
    parser=argparse.ArgumentParser(__doc__)
    parser.add_argument('mode',choices=('status','query','gallery','download','quota'))
    parser.add_argument('mod',type=Path)
    parser.add_argument('images',nargs='*',type=Path)
    args=parser.parse_args()
    match=re.search(r'^id=(\d+)$',(args.mod/'workshop/workshop.txt').read_text(),re.M)
    assert args.mode in ('status','quota') or match, 'Published item ID required'
    item=int(match.group(1)) if match else None
    images=[p.resolve() for p in args.images]
    steam=Steam()
    try:
        if args.mode=='quota': print('STEAM_CLOUD_QUOTA '+str(steam.quota()))
        elif args.mode=='query': print(json.dumps(steam.previews(item),indent=2))
        elif args.mode=='gallery': steam.gallery(item,images)
        elif args.mode=='download': steam.download(item)
    finally:
        steam.shutdown()


if __name__=='__main__':
    main()
