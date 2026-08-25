# -*- coding: utf-8 -*-
# Puntos individuales IBK por distrito -> binarios servidos on-demand (lote exacto, coloreados por precision).
import pandas as pd, numpy as np, geopandas as gpd, os, struct, time
from pyproj import Transformer
t0=time.time()
CASC='C:/Users/CARLOS/Downloads/Data_geo/Data_geo/data/salida/geocodificado_cascada.parquet'
OUT='C:/Users/CARLOS/Downloads/Data_geo/Data_geo/data/salida/ibk_pts'
os.makedirs(OUT,exist_ok=True)
susc=gpd.read_file('cenepred/Shape/susc_mmasa_pp.shp'); xmin,ymin,xmax,ymax=susc.total_bounds; res=550.0
W=int((xmax-xmin)/res); H=int((ymax-ymin)/res)
print(f'grid mapa {W}x{H}',flush=True)

df=pd.read_parquet(CASC,columns=['ubigeo_limpio','lon_final','lat_final','radio_final']).dropna(subset=['lon_final','lat_final'])
df=df[df['ubigeo_limpio'].notna() & (df['ubigeo_limpio'].astype(str).str.len()==6)]
tr=Transformer.from_crs('EPSG:4326','EPSG:32718',always_xy=True)
X,Y=tr.transform(df['lon_final'].values, df['lat_final'].values)
df['col']=((np.array(X)-xmin)/res).astype('float32')   # unidades de grid (550m), float => posicion exacta
df['row']=((ymax-np.array(Y))/res).astype('float32')
r=df['radio_final'].values*1000
df['tier']=np.where(r<=300,0,np.where(r<=500,1,np.where(r<=1000,2,3))).astype('uint8')
df=df[(df['col']>=0)&(df['col']<W)&(df['row']>=0)&(df['row']<H)]
print(f'puntos {len(df):,} | distritos {df.ubigeo_limpio.nunique():,}',flush=True)

n=0; big=[]
for ub,g in df.groupby('ubigeo_limpio'):
    c=g['col'].values.astype('<f4'); rw=g['row'].values.astype('<f4'); t=g['tier'].values.astype('u1')
    with open(f'{OUT}/{ub}.bin','wb') as f:
        f.write(struct.pack('<I',len(g))); f.write(c.tobytes()); f.write(rw.tobytes()); f.write(t.tobytes())
    n+=1
    if len(g)>30000: big.append((ub,len(g)))
print(f'{n:,} archivos escritos en {time.time()-t0:.0f}s',flush=True)
big.sort(key=lambda x:-x[1]); print('distritos mas densos:', big[:6])
tot=sum(os.path.getsize(f'{OUT}/{f}') for f in os.listdir(OUT))
print(f'tamaño total ibk_pts/: {tot/1e6:.1f} MB')
