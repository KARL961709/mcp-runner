# -*- coding: utf-8 -*-
# Peligro BINARIO: Unificado (max inund, mov masa), solo Muy Alto = rojo ("Altamente susceptible"), resto gris.
import geopandas as gpd, numpy as np, pandas as pd
from rasterio.features import rasterize
from rasterio.transform import from_bounds
from PIL import Image
S='cenepred/Shape/'; B='C:/Users/CARLOS/elnino_ibk'
def cls(s):
    s=str(s).lower(); return 4 if('muy' in s and 'alt' in s) else 3 if 'alt' in s else 2 if 'med' in s else 1 if 'baj' in s else 0
g=gpd.read_file(S+'susc_mmasa_pp.shp'); g['c']=g['N_SMMPP'].map(cls).astype('uint8')
xmin,ymin,xmax,ymax=g.total_bounds; res=180.0; W=int((xmax-xmin)/res); H=int((ymax-ymin)/res)
tr=from_bounds(xmin,ymin,xmax,ymax,W,H)
mm=rasterize(((geom,c) for geom,c in zip(g.geometry,g.c)),(H,W),transform=tr,fill=0,dtype='uint8')
gi=gpd.read_file(S+'susc_inund_pp.shp'); gi['c']=gi['N_SInunPP'].map(cls).astype('uint8')
inu=rasterize(((geom,c) for geom,c in zip(gi.geometry,gi.c)),(H,W),transform=tr,fill=0,dtype='uint8')
uni=np.maximum(mm,inu)
# gate Pacifico + base Peru
fen=pd.read_csv(B+'/02_pipeline/out/grado_fen_v3.csv',dtype={'ubigeo':str})
pac=set(fen[pd.to_numeric(fen['pacifico'])==1]['ubigeo'])
d=gpd.read_file(S+'Riesgo_MMasa_Distritos.shp')[['UBIGEO','geometry']].to_crs(g.crs)
base=rasterize(((geom,1) for geom in d.geometry),(H,W),transform=tr,fill=0,dtype='uint8')
pm=rasterize(((geom,1) for geom in d[d['UBIGEO'].isin(pac)].geometry),(H,W),transform=tr,fill=0,dtype='uint8')
muyalto=(np.where(pm==1,uni,0)==4)
GREY=(223,229,234); RED=(174,26,26)
im=np.zeros((H,W,3),np.uint8)
im[base==1]=GREY
im[muyalto]=RED
Image.fromarray(im,'RGB').save('C:/Users/CARLOS/Downloads/Data_geo/Data_geo/data/salida/fen_altasusc.png',optimize=True)
import os
print('fen_altasusc.png',round(os.path.getsize('C:/Users/CARLOS/Downloads/Data_geo/Data_geo/data/salida/fen_altasusc.png')/1e6,2),'MB | celdas Muy Alto:',int(muyalto.sum()))
