# -*- coding: utf-8 -*-
# Flags de precision + distancia a peligro Unificado (Muy Alto; Alto+Muy Alto), gate Pacifico, por punto lote.
import time; t0=time.time()
import geopandas as gpd, numpy as np, pandas as pd
from rasterio.features import rasterize
from rasterio.transform import from_bounds
from scipy.ndimage import distance_transform_edt
from pyproj import Transformer
S='cenepred/Shape/'; B='C:/Users/CARLOS/elnino_ibk'
CASC='C:/Users/CARLOS/Downloads/Data_geo/Data_geo/data/salida/geocodificado_cascada.parquet'
def cls(s):
    s=str(s).lower(); return 4 if('muy' in s and 'alt' in s) else 3 if 'alt' in s else 2 if 'med' in s else 1 if 'baj' in s else 0

g=gpd.read_file(S+'susc_mmasa_pp.shp'); g['c']=g['N_SMMPP'].map(cls).astype('uint8')
xmin,ymin,xmax,ymax=g.total_bounds; res=180.0; W=int((xmax-xmin)/res); H=int((ymax-ymin)/res)
cellx=(xmax-xmin)/W; celly=(ymax-ymin)/H
tr=from_bounds(xmin,ymin,xmax,ymax,W,H)
print(f'grid {W}x{H} | celda ~{cellx:.0f}x{celly:.0f} m | {time.time()-t0:.0f}s',flush=True)
mm=rasterize(((geom,c) for geom,c in zip(g.geometry,g.c)),(H,W),transform=tr,fill=0,dtype='uint8')
gi=gpd.read_file(S+'susc_inund_pp.shp'); gi['c']=gi['N_SInunPP'].map(cls).astype('uint8')
inu=rasterize(((geom,c) for geom,c in zip(gi.geometry,gi.c)),(H,W),transform=tr,fill=0,dtype='uint8')
uni=np.maximum(mm,inu); del mm,inu
# gate Pacifico
fen=pd.read_csv(B+'/02_pipeline/out/grado_fen_v3.csv',dtype={'ubigeo':str})
pac=set(fen[pd.to_numeric(fen['pacifico'])==1]['ubigeo'])
d=gpd.read_file(S+'Riesgo_MMasa_Distritos.shp')[['UBIGEO','geometry']].to_crs(g.crs)
pm=rasterize(((geom,1) for geom in d[d['UBIGEO'].isin(pac)].geometry),(H,W),transform=tr,fill=0,dtype='uint8')
uni=np.where(pm==1,uni,0).astype('uint8'); del pm
print(f'raster listo | {time.time()-t0:.0f}s | distancia...',flush=True)
dist_ma=(distance_transform_edt(uni!=4)*cellx).astype('float32')
dist_am=(distance_transform_edt(uni<3)*cellx).astype('float32'); del uni
print(f'distancias listas | {time.time()-t0:.0f}s | muestreando puntos...',flush=True)

df=pd.read_parquet(CASC,columns=['clave','ubigeo_limpio','distrito_limpio','lon_final','lat_final','radio_final','fuente_xy_final']).dropna(subset=['lon_final','lat_final'])
tr2=Transformer.from_crs('EPSG:4326','EPSG:32718',always_xy=True)
X,Y=tr2.transform(df.lon_final.values,df.lat_final.values)
col=((np.array(X)-xmin)/cellx).astype(int); row=((ymax-np.array(Y))/celly).astype(int)
inb=(col>=0)&(col<W)&(row>=0)&(row<H); ci=np.clip(col,0,W-1); ri=np.clip(row,0,H-1)
dm=np.where(inb,dist_ma[ri,ci],np.nan); da=np.where(inb,dist_am[ri,ci],np.nan)
df['dist_ma_m']=np.round(dm).astype('float32'); df['dist_am_m']=np.round(da).astype('float32')
# precision
p=(df.radio_final*1000).values
df['prec_m']=p
df['prec_tier']=pd.cut(p,[-1,50,100,300,500,1000,1e12],labels=['<=50m','51-100m','101-300m','301-500m','501-1000m','>1km'])
for lab,lo,hi in [('p50',-1,50),('p100',50,100),('p300',100,300),('p500',300,500),('p1k',500,1000),('pgt1k',1000,1e12)]:
    df['flg_prec_'+lab]=((p>lo)&(p<=hi)).astype('int8')
# distancia (acumulativo dentro de X)
for band in [100,300,500,1000]:
    df[f'flg_ma_{band}']=(df.dist_ma_m<=band).astype('int8')
    df[f'flg_am_{band}']=(df.dist_am_m<=band).astype('int8')
OUT='C:/Users/CARLOS/Downloads/Data_geo/Data_geo/data/salida/flags_proximidad.parquet'
df.to_parquet(OUT,index=False)
print(f'=== GUARDADO {OUT} | {len(df):,} filas | {time.time()-t0:.0f}s ===',flush=True)
print('\n=== PRECISION (prec_tier) ==='); print(df['prec_tier'].value_counts().reindex(['<=50m','51-100m','101-300m','301-500m','501-1000m','>1km']).to_string())
print('\n=== DENTRO DE X de MUY ALTO (Unificado) ===')
for band in [100,300,500,1000]:
    n=int(df[f'flg_ma_{band}'].sum()); print(f'  <= {band:4d} m : {n:9,} ({100*n/len(df):.1f}%)')
print('\n=== DENTRO DE X de ALTO+MUY ALTO (Unificado) ===')
for band in [100,300,500,1000]:
    n=int(df[f'flg_am_{band}'].sum()); print(f'  <= {band:4d} m : {n:9,} ({100*n/len(df):.1f}%)')
print('\n=== CRUCE precise (<=300m) x cerca de Muy Alto ===')
prec=df[df['prec_m']<=300]
print(f'  puntos precisos <=300m: {len(prec):,}')
for band in [100,300,500,1000]:
    n=int(prec[f'flg_ma_{band}'].sum()); print(f'    de esos, <= {band:4d} m de Muy Alto: {n:8,} ({100*n/len(prec):.1f}%)')
