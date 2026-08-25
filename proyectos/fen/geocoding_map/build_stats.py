# -*- coding: utf-8 -*-
# Composicion por distrito (para la tarjeta): de los puntos <=300m, cuantos caen en Muy Alto / Alto / Fuera.
# Deriva de flags_proximidad.parquet (contencion = distancia 0). Salida: dist_stats.json {ubigeo:{t,p,ma,al,no}}.
import pandas as pd, json
SAL='C:/Users/CARLOS/Downloads/Data_geo/Data_geo/data/salida/'
df=pd.read_parquet(SAL+'flags_proximidad.parquet',columns=['ubigeo_limpio','radio_final','dist_ma_m','dist_am_m'])
df=df[df['ubigeo_limpio'].astype(str).str.len()==6]
df['prec']=(df['radio_final']*1000)<=300
df['ma']=(df['dist_ma_m']==0)
df['alto']=(df['dist_am_m']==0)&(df['dist_ma_m']>0)
stats={}
for ub,g in df.groupby('ubigeo_limpio'):
    p=g[g['prec']]
    stats[ub]={'t':int(len(g)),'p':int(len(p)),'ma':int(p['ma'].sum()),'al':int(p['alto'].sum()),
               'no':int(len(p)-p['ma'].sum()-p['alto'].sum())}
json.dump(stats,open(SAL+'dist_stats.json','w'))
print('dist_stats.json:',len(stats),'distritos')
