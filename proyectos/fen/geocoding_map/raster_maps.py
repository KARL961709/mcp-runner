# -*- coding: utf-8 -*-
import time; t0=time.time()
import geopandas as gpd, numpy as np, pandas as pd
from rasterio.features import rasterize
from rasterio.transform import from_bounds
from PIL import Image
B='C:/Users/CARLOS/elnino_ibk'; S='cenepred/Shape/'

def cls(s):
    s=str(s).lower()
    return 4 if('muy' in s and 'alt' in s) else 3 if 'alt' in s else 2 if 'med' in s else 1 if 'baj' in s else 0

print('leyendo susceptibilidad fina MM...', flush=True)
g=gpd.read_file(S+'susc_mmasa_pp.shp'); g['cls']=g['N_SMMPP'].map(cls).astype('uint8')
xmin,ymin,xmax,ymax=g.total_bounds
res=180.0; W=int((xmax-xmin)/res); H=int((ymax-ymin)/res)   # 180m: bordes nitidos al hacer zoom
tr=from_bounds(xmin,ymin,xmax,ymax,W,H)
print(f'rasterizando MM {W}x{H}...', flush=True)
arr_mm=rasterize(((geom,c) for geom,c in zip(g.geometry,g['cls'])), out_shape=(H,W), transform=tr, fill=0, dtype='uint8')

print('leyendo susceptibilidad fina INUNDACION...', flush=True)
gi=gpd.read_file(S+'susc_inund_pp.shp'); gi['cls']=gi['N_SInunPP'].map(cls).astype('uint8')
print(f'rasterizando INUND {W}x{H}...', flush=True)
arr_in=rasterize(((geom,c) for geom,c in zip(gi.geometry,gi['cls'])), out_shape=(H,W), transform=tr, fill=0, dtype='uint8')

print('base Peru + mascara Pacifico...', flush=True)
fen=pd.read_csv(B+'/02_pipeline/out/grado_fen_v3.csv', dtype={'ubigeo':str})
pac=set(fen[pd.to_numeric(fen['pacifico'])==1]['ubigeo'])
d=gpd.read_file(S+'Riesgo_MMasa_Distritos.shp')[['UBIGEO','geometry']].to_crs(g.crs)
base=rasterize(((geom,1) for geom in d.geometry), out_shape=(H,W), transform=tr, fill=0, dtype='uint8')
pacmask=rasterize(((geom,1) for geom in d[d['UBIGEO'].isin(pac)].geometry), out_shape=(H,W), transform=tr, fill=0, dtype='uint8')

GREY=(42,53,66,255)  # tierra oscura (tema dark) = R0 del score FEN
# paleta homogenea con el score FEN distrital: Medio ambar, Alto naranja, Muy alto rojo oscuro
RAMP={2:(251,179,95,255),3:(233,108,57,255),4:(174,26,26,255)}
# --- MM fino: base gris + MM (solo Pacifico) ---
mm=np.where(pacmask==1,arr_mm,0)
im=np.zeros((H,W,4),np.uint8); im[base==1]=GREY
for k,c in RAMP.items(): im[mm==k]=c
Image.fromarray(im,'RGBA').convert('RGB').save('fen_mm.png',optimize=True)
# --- Inundacion FINA: base gris + inund (solo Pacifico) ---
inm=np.where(pacmask==1,arr_in,0)
im2=np.zeros((H,W,4),np.uint8); im2[base==1]=GREY
for k,c in RAMP.items(): im2[inm==k]=c
Image.fromarray(im2,'RGBA').convert('RGB').save('fen_inund.png',optimize=True)
print('clases inund (zona FEN):', dict(zip(*[x.tolist() for x in np.unique(inm,return_counts=True)])))
# --- UNIFICADO: MAX(inundacion, mov.masa) ---
uni=np.maximum(inm,mm)
im3=np.zeros((H,W,4),np.uint8); im3[base==1]=GREY
for k,c in RAMP.items(): im3[uni==k]=c
Image.fromarray(im3,'RGBA').convert('RGB').save('fen_max.png',optimize=True)
both=int(((inm>0)&(mm>0)).sum()); anyh=int((uni>0).sum())
print(f'SOLAPAMIENTO -> ambos peligros: {both:,} celdas | union total: {anyh:,} | % del union con AMBOS: {100*both/max(anyh,1):.1f}%')
print('clases unificado:', dict(zip(*[x.tolist() for x in np.unique(uni,return_counts=True)])))

import os, shutil
for f in ['fen_mm.png','fen_inund.png','fen_max.png']:
    shutil.copy(f, 'C:/Users/CARLOS/Downloads/Data_geo/Data_geo/data/salida/'+f)
print('MM:',round(os.path.getsize('fen_mm.png')/1e6,2),'MB | Inund:',round(os.path.getsize('fen_inund.png')/1e6,2),'MB |',round(time.time()-t0),'s |',f'{W}x{H}')
