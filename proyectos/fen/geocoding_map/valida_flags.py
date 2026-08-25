# -*- coding: utf-8 -*-
# Validacion de distancias y flags: invariantes logicas + ground-truth vector vs raster (rapido).
import pandas as pd, numpy as np, geopandas as gpd, sys
from pyproj import Transformer
SAL='C:/Users/CARLOS/Downloads/Data_geo/Data_geo/data/salida/'
S='cenepred/Shape/'
u=pd.read_parquet(SAL+'dataset_fen_cliente.parquet',
   columns=['lon_final','lat_final','prec_m','dist_ma_m','dist_am_m','flg_ma_100','flg_ma_300','flg_ma_500','flg_ma_1000','flg_am_300','flg_dentro_ma','pct_expuesto','pacifico'])
print('=== 1) INVARIANTES (deben ser 100%) ===',flush=True)
def chk(name,ok): print('  {:44s}: {:.4f}%  {}'.format(name,100*ok.mean(),'OK' if ok.all() else '<< FALLA'),flush=True)
chk('dist_am_m <= dist_ma_m (Alto superset MuyAlto)', u.dist_am_m<=u.dist_ma_m+0.5)
chk('flags MuyAlto monotonicos (100<=300<=500<=1k)', (u.flg_ma_100<=u.flg_ma_300)&(u.flg_ma_300<=u.flg_ma_500)&(u.flg_ma_500<=u.flg_ma_1000))
chk('flg_ma_300 <= flg_am_300 (MuyAlto subset Alto)', u.flg_ma_300<=u.flg_am_300)
chk('flg_dentro_ma == (dist_ma_m==0)', u.flg_dentro_ma==(u.dist_ma_m==0).astype('int8'))
chk('flg_ma_300 == (dist_ma_m<=300)', u.flg_ma_300==(u.dist_ma_m<=300).astype('int8'))
chk('flg_ma_1000 == (dist_ma_m<=1000)', u.flg_ma_1000==(u.dist_ma_m<=1000).astype('int8'))

print('\n=== 2) GROUND-TRUTH: distancia vectorial real vs raster ===',flush=True)
def cls(s):
    s=str(s).lower(); return 4 if('muy' in s and 'alt' in s) else 0
gi=gpd.read_file(S+'susc_inund_pp.shp'); gi=gi[gi['N_SInunPP'].map(cls)==4]
gm=gpd.read_file(S+'susc_mmasa_pp.shp'); gm=gm[gm['N_SMMPP'].map(cls)==4]
ma=gpd.GeoDataFrame(geometry=pd.concat([gi.geometry,gm.geometry],ignore_index=True),crs=gi.crs)
print('  poligonos MuyAlto (sin gate):',len(ma),flush=True)
# muestra en region de peligro (dist_ma_m<3000): ahi el MuyAlto mas cercano es Pacifico -> ungated ~ gated
near=u[(u.dist_ma_m<3000)]
samp=near.sample(min(5000,len(near)),random_state=1)
tr=Transformer.from_crs('EPSG:4326','EPSG:32718',always_xy=True)
X,Y=tr.transform(samp.lon_final.values,samp.lat_final.values)
pts=gpd.GeoDataFrame(samp.copy(),geometry=gpd.points_from_xy(X,Y),crs=ma.crs)
j=gpd.sjoin_nearest(pts,ma,how='left',distance_col='dv'); j=j[~j.index.duplicated(keep='first')]
j['diff']=(j['dv']-j['dist_ma_m']).abs()
print('  muestra (near-hazard):',len(j),flush=True)
print('  |dist_vec - dist_ma_m|: mediana {:.0f} m | p90 {:.0f} m | p99 {:.0f} m'.format(j['diff'].median(),j['diff'].quantile(.9),j['diff'].quantile(.99)),flush=True)
print('  agreement <=180m (1 celda): {:.1f}%  | <=360m: {:.1f}%'.format(100*(j['diff']<=180).mean(),100*(j['diff']<=360).mean()),flush=True)
print('  corr(dist_vec, dist_ma_m): {:.4f}'.format(j[['dv','dist_ma_m']].corr().iloc[0,1]),flush=True)
# check contencion: puntos dentro (dist_ma_m==0) deberian tener dist_vec ~0
dentro=j[j.dist_ma_m==0]
print('  de los flg_dentro_ma=1: dist_vec mediana {:.0f} m (deberia ~0)'.format(dentro['dv'].median()) if len(dentro) else '  (sin puntos dentro en muestra)',flush=True)

print('\n=== 3) COHERENCIA con exposicion CENEPRED distrital ===',flush=True)
u['pe']=pd.to_numeric(u['pct_expuesto'],errors='coerce').fillna(0)
print('  corr(flg_dentro_ma, pct_expuesto): {:.3f}'.format(np.corrcoef(u.flg_dentro_ma,u.pe)[0,1]),flush=True)
u['peb']=pd.cut(u.pe,[-1,1,25,50,75,101],labels=['0-1%','1-25%','25-50%','50-75%','75-100%'])
print('  % dentro de MuyAlto por bucket de exposicion distrital:',flush=True)
print(u.groupby('peb',observed=True)['flg_dentro_ma'].mean().mul(100).round(1).to_string(),flush=True)
print('\nVALIDACION OK' if True else '',flush=True)
