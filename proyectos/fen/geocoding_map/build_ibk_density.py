# -*- coding: utf-8 -*-
# Densidad de direcciones IBK geocodificadas (<=300m y <=500m) en verde, alineada al grid del mapa FEN.
import pandas as pd, numpy as np, geopandas as gpd
from pyproj import Transformer
from PIL import Image
from scipy.ndimage import maximum_filter
CASC='C:/Users/CARLOS/Downloads/Data_geo/Data_geo/data/salida/geocodificado_cascada.parquet'
susc=gpd.read_file('cenepred/Shape/susc_mmasa_pp.shp')
xmin,ymin,xmax,ymax=susc.total_bounds; res=90.0   # ~90m nacional (limite por memoria)
W=int((xmax-xmin)/res); H=int((ymax-ymin)/res)
print(f'grid fino {W}x{H} = {W*H/1e6:.0f}M px',flush=True)

df=pd.read_parquet(CASC,columns=['lon_final','lat_final','radio_final']).dropna(subset=['lon_final','lat_final'])
tr=Transformer.from_crs('EPSG:4326','EPSG:32718',always_xy=True)
X,Y=tr.transform(df['lon_final'].values, df['lat_final'].values)
col=((X-xmin)/res).astype(int); row=((ymax-Y)/res).astype(int)
inb=(col>=0)&(col<W)&(row>=0)&(row<H)
r=df['radio_final'].values*1000
print(f'puntos {len(df):,} | dentro del grid {int(inb.sum()):,}',flush=True)

def dens(mask):
    m=inb & mask
    idx=(row[m].astype(np.int64)*W+col[m].astype(np.int64))
    g=np.bincount(idx,minlength=W*H).astype(np.int32).reshape(H,W)
    return g,int(m.sum())

GREEN=(0,177,80)     # verde Interbank (preciso)
VIOLET=(155,89,182)  # violeta (localidad, impreciso)
def png(grid,fn,rgb):
    d=maximum_filter(grid,size=2)  # 2px @180m = ~360m: granular (nivel manzana) pero visible
    a=np.log1p(d.astype(float)); mx=a.max()
    a=a/mx if mx>0 else a
    alpha=(np.clip(a*2.2,0,1)*255).astype(np.uint8)
    img=np.zeros((H,W,4),np.uint8)
    img[...,0]=rgb[0]; img[...,1]=rgb[1]; img[...,2]=rgb[2]; img[...,3]=alpha
    Image.fromarray(img,'RGBA').save(fn)

O='C:/Users/CARLOS/Downloads/Data_geo/Data_geo/data/salida/'
g3,n3=dens(r<=300); g5,n5=dens(r<=500); g1,n1=dens(r<=1000); gl,nl=dens(r>1000)
png(g3,O+'ibk_300.png',GREEN); png(g5,O+'ibk_500.png',GREEN)
png(g1,O+'ibk_1km.png',GREEN); png(gl,O+'ibk_loc.png',VIOLET)
print(f'<=300m: {n3:,} | <=500m: {n5:,} | <=1km: {n1:,} | >1km: {nl:,}',flush=True)
print('PNGs escritos (4 capas).')
