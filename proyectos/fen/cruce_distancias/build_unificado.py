# -*- coding: utf-8 -*-
# Genera el UNIFICADO = MAX(inundacion, mov masa), gate Pacifico: como GeoTIFF (lo que se cruza) y como shapefile (clases Alto+MuyAlto).
import geopandas as gpd, numpy as np, pandas as pd, os
from rasterio.features import rasterize, shapes
from rasterio.transform import from_bounds
import rasterio
from shapely.geometry import shape
S='cenepred/Shape/'; B='C:/Users/CARLOS/elnino_ibk'
OUT='C:/Users/CARLOS/Downloads/Data_geo/Data_geo/data/salida/PROYECTO_CRUCE_FEN/4_unificado/'
os.makedirs(OUT,exist_ok=True)
def cls(s):
    s=str(s).lower(); return 4 if('muy' in s and 'alt' in s) else 3 if 'alt' in s else 2 if 'med' in s else 1 if 'baj' in s else 0
g=gpd.read_file(S+'susc_mmasa_pp.shp'); g['c']=g['N_SMMPP'].map(cls).astype('uint8')
xmin,ymin,xmax,ymax=g.total_bounds; res=180.0; W=int((xmax-xmin)/res); H=int((ymax-ymin)/res)
tr=from_bounds(xmin,ymin,xmax,ymax,W,H)
mm=rasterize(((geom,c) for geom,c in zip(g.geometry,g.c)),(H,W),transform=tr,fill=0,dtype='uint8')
gi=gpd.read_file(S+'susc_inund_pp.shp'); gi['c']=gi['N_SInunPP'].map(cls).astype('uint8')
inu=rasterize(((geom,c) for geom,c in zip(gi.geometry,gi.c)),(H,W),transform=tr,fill=0,dtype='uint8')
uni=np.maximum(mm,inu)
# gate Pacifico
fen=pd.read_csv(B+'/02_pipeline/out/grado_fen_v3.csv',dtype={'ubigeo':str})
pac=set(fen[pd.to_numeric(fen['pacifico'])==1]['ubigeo'])
d=gpd.read_file(S+'Riesgo_MMasa_Distritos.shp')[['UBIGEO','geometry']].to_crs(g.crs)
pm=rasterize(((geom,1) for geom in d[d['UBIGEO'].isin(pac)].geometry),(H,W),transform=tr,fill=0,dtype='uint8')
uni=np.where(pm==1,uni,0).astype('uint8')
# 1) GeoTIFF (lo que muestrea el cruce)
with rasterio.open(OUT+'fen_unificado.tif','w',driver='GTiff',height=H,width=W,count=1,dtype='uint8',
                   crs=g.crs,transform=tr,compress='deflate',nodata=0) as dst:
    dst.write(uni,1)
    dst.write_colormap(1,{0:(0,0,0,0),1:(200,220,180,255),2:(240,220,120,255),3:(232,120,30,255),4:(200,20,20,255)})
print('GeoTIFF:', round(os.path.getsize(OUT+'fen_unificado.tif')/1e6,2),'MB | Muy Alto celdas:',int((uni==4).sum()),'| Alto:',int((uni==3).sum()))
# 2) shapefile de clases Alto (3) y Muy Alto (4)
recs=[]
for geom,val in shapes(uni,mask=(uni>=3),transform=tr):
    recs.append({'geometry':shape(geom),'clase':int(val),'nivel':'Muy Alto' if val==4 else 'Alto'})
gdf=gpd.GeoDataFrame(recs,crs=g.crs)
gdf.to_file(OUT+'fen_unificado_alto_muyalto.shp')
print('shapefile unificado:', len(gdf),'poligonos |', round(sum(os.path.getsize(OUT+'fen_unificado_alto_muyalto'+e) for e in ['.shp','.dbf','.shx'] if os.path.exists(OUT+'fen_unificado_alto_muyalto'+e))/1e6,2),'MB')
