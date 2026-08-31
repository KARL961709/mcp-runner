# -*- coding: utf-8 -*-
# Fusiona rescates Google al cascada, con gate espacial (point-in-distrito) y regla de mejora vs ArcGIS localidad.
import pandas as pd, geopandas as gpd, sqlite3, unicodedata, re, time
t0=time.time()
CASC='C:/Users/CARLOS/Downloads/Data_geo/Data_geo/data/salida/geocodificado_cascada.parquet'
CACHE='google_cache.sqlite'
G='C:/Users/CARLOS/elnino_ibk/01_inputs/geo/'
def norm(s):
    s=unicodedata.normalize('NFD',str(s or '')); s=''.join(c for c in s if unicodedata.category(c)!='Mn')
    return re.sub(r'\s+',' ',re.sub(r'[^A-Z0-9 ]',' ',s.upper())).strip()

RESCUE={'ROOFTOP','RANGE_INTERPOLATED','GEOMETRIC_CENTER'}
NIV={'ROOFTOP':('direccion_google',0.02),'RANGE_INTERPOLATED':('calle_google',0.08),'GEOMETRIC_CENTER':('manzana_google',0.30)}

df=pd.read_parquet(CASC)
con=sqlite3.connect(CACHE); g=pd.read_sql('SELECT clave,lon,lat,ltype FROM g',con); con.close()
g=g[g['lon'].notna()].copy()
print(f'cascada {len(df):,} | google con XY {len(g):,} | {time.time()-t0:.0f}s',flush=True)

mask=df['estado_cascada']=='candidato_google'
idx=df.index[mask]
cand=df.loc[idx,['clave','ubigeo_limpio','distrito_limpio']].merge(
    g.rename(columns={'lon':'glon','lat':'glat'}),on='clave',how='left')
cand.index=idx
has=cand['glon'].notna()
print(f'candidatos {mask.sum():,} | con respuesta google {has.sum():,}',flush=True)

# gate espacial
pts=gpd.GeoDataFrame(cand[has].copy(),geometry=gpd.points_from_xy(cand.loc[has,'glon'],cand.loc[has,'glat']),crs='EPSG:4326')
dist=gpd.read_file(G+'peru_dist.geojson')[['IDDIST','NOMBDIST','geometry']].to_crs('EPSG:4326')
dist['ndist']=dist['NOMBDIST'].map(norm)
j=gpd.sjoin(pts,dist[['IDDIST','ndist','geometry']],how='left',predicate='within')
j=j[~j.index.duplicated(keep='first')]
okd=((j['IDDIST'].astype(str)==j['ubigeo_limpio'].astype(str)) |
     (j['ndist']==j['distrito_limpio'].map(norm)))
cand['ok_dist']=False
cand.loc[okd.index,'ok_dist']=okd.values
print(f'dentro de distrito {int(cand["ok_dist"].sum()):,} / {has.sum():,} | {time.time()-t0:.0f}s',flush=True)

is_none=~has
is_out=has & (~cand['ok_dist'])
is_resc=has & cand['ok_dist'] & cand['ltype'].isin(RESCUE)
is_noimp=has & cand['ok_dist'] & (~cand['ltype'].isin(RESCUE))  # APPROXIMATE dentro de distrito

# aplicar
df.loc[idx[is_none.values],'estado_cascada']='google_none'
df.loc[idx[is_out.values],'estado_cascada']='google_fuera_distrito'
df.loc[idx[is_noimp.values],'estado_cascada']='google_sin_mejora'
ri=idx[is_resc.values]
df.loc[ri,'estado_cascada']='google_rescatado'
df.loc[ri,'fuente_xy_final']='google'
df.loc[ri,'lon_final']=cand.loc[is_resc,'glon'].values
df.loc[ri,'lat_final']=cand.loc[is_resc,'glat'].values
df.loc[ri,'nivel_final']=cand.loc[is_resc,'ltype'].map(lambda t:NIV[t][0]).values
df.loc[ri,'radio_final']=cand.loc[is_resc,'ltype'].map(lambda t:NIV[t][1]).values

df.to_parquet(CASC,index=False)
print(f'=== GUARDADO | {time.time()-t0:.0f}s ===',flush=True)
print('estado_cascada final:'); print(df['estado_cascada'].value_counts())
print('\nrescatados por tipo:'); print(cand.loc[is_resc,'ltype'].value_counts())
tot_xy=(df['lon_final'].notna()).sum()
print(f'\ncobertura X,Y final: {tot_xy:,} / {len(df):,} ({100*tot_xy/len(df):.1f}%)')
