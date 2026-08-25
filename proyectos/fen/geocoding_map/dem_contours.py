# -*- coding: utf-8 -*-
import urllib.request, math, io, json
from concurrent.futures import ThreadPoolExecutor
import numpy as np
from PIL import Image
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt
from shapely.geometry import LineString
from pyproj import Transformer
import geopandas as gpd

Z=8
def tilexy(lon,lat):
    x=int((lon+180)/360*2**Z); y=int((1-math.log(math.tan(math.radians(lat))+1/math.cos(math.radians(lat)))/math.pi)/2*2**Z); return x,y
x0,y0=tilexy(-81.4,0.0); x1,y1=tilexy(-68.6,-18.4)
NX=x1-x0+1; NY=y1-y0+1
print(f'bajando {NX*NY} tiles z{Z}...', flush=True)

def get(tx,ty):
    url=f'https://s3.amazonaws.com/elevation-tiles-prod/terrarium/{Z}/{tx}/{ty}.png'
    for _ in range(3):
        try:
            d=urllib.request.urlopen(url,timeout=30).read()
            a=np.array(Image.open(io.BytesIO(d)).convert('RGB')).astype('float32')
            return (tx,ty,(a[:,:,0]*256+a[:,:,1]+a[:,:,2]/256)-32768)
        except Exception: pass
    return (tx,ty,np.full((256,256),-32768,'float32'))

mos=np.full((NY*256,NX*256),np.nan,'float32')
with ThreadPoolExecutor(max_workers=16) as ex:
    for tx,ty,arr in ex.map(lambda t:get(*t), [(tx,ty) for ty in range(y0,y1+1) for tx in range(x0,x1+1)]):
        r=(ty-y0)*256; c=(tx-x0)*256; mos[r:r+256,c:c+256]=arr
mos[mos<-1000]=np.nan
print('mosaico', mos.shape, '| elev', np.nanmin(mos), np.nanmax(mos), flush=True)

# grid del mapa (susc bounds, res 550, UTM18S) para proyectar
susc=gpd.read_file('cenepred/Shape/susc_mmasa_pp.shp'); xmin,ymin,xmax,ymax=susc.total_bounds; res=550.0
tr=Transformer.from_crs('EPSG:4326','EPSG:32718',always_xy=True)
def merc_pix_to_mappix(cols,rows):
    fx=x0+cols/256.0; fy=y0+rows/256.0
    lon=fx/2**Z*360-180
    lat=np.degrees(np.arctan(np.sinh(np.pi*(1-2*fy/2**Z))))
    X,Y=tr.transform(lon,lat)
    return (np.array(X)-xmin)/res, (ymax-np.array(Y))/res

LEV=[250,500,750,1000,1500,2000,2500,3000,3500,4000,4500]
BPc=np.array([0,1500,3000,4500]); RC=np.array([[60,150,80],[220,190,95],[190,110,60],[110,70,45]],float)
def _col(l): return '#%02x%02x%02x'%(int(np.interp(l,BPc,RC[:,0])),int(np.interp(l,BPc,RC[:,1])),int(np.interp(l,BPc,RC[:,2])))
COL={l:_col(l) for l in LEV}
dem=np.nan_to_num(mos, nan=-100)
cs=plt.contour(dem, levels=LEV)
cotas=[]
for lvl,segs in zip(cs.levels, cs.allsegs):
    for seg in segs:
        if len(seg)<8: continue
        px,py=merc_pix_to_mappix(seg[:,0],seg[:,1])
        ls=LineString(np.column_stack([px,py])).simplify(2.0)
        if ls.is_empty or len(ls.coords)<4: continue
        d=''.join(('M' if i==0 else 'L')+f'{x:.0f} {y:.0f}' for i,(x,y) in enumerate(ls.coords))
        cotas.append({'d':d,'lvl':int(lvl),'c':COL[int(lvl)]})
print('segmentos de cota:', len(cotas), flush=True)

ov=json.load(open('overlays.json',encoding='utf-8'))
ov['cotas']=cotas; ov['cota_leg']=[[COL[l],f'{l}' if l<1000 else f'{l/1000:.1f}k'] for l in [250,1000,2000,3000,4500]]
open('overlays.json','w',encoding='utf-8').write(json.dumps(ov,ensure_ascii=False,separators=(',',':')))
import os; print('overlays.json', round(os.path.getsize('overlays.json')/1024),'KB')
