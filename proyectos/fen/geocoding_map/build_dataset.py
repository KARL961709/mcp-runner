# -*- coding: utf-8 -*-
# Dataset unificado por cliente: geo + precision + proximidad + grado FEN + eventos + impacto2017 + prensa + flags propuestos.
import pandas as pd, json, numpy as np
SAL='C:/Users/CARLOS/Downloads/Data_geo/Data_geo/data/salida/'
f=pd.read_parquet(SAL+'flags_proximidad.parquet')
f['flg_dentro_ma']=(f['dist_ma_m']==0).astype('int8')
f['flg_dentro_alto']=(f['dist_am_m']==0).astype('int8')

# --- grado FEN + score + flags por anio ---
v6=pd.read_csv('C:/Users/CARLOS/elnino_ibk/02_pipeline/out/grado_fen_v6.csv',dtype=str).drop_duplicates('ubigeo')
YRS=['a1983','a1987','a1992','a1998','a2016','a2017','a2023','a2024','a2026']
keep=['ubigeo','departamento','provincia','cuenca_canon','pacifico','R_nivel','patron_evento','n_eventos','pct_expuesto','sev','rec','fra','exp_n','score','gate_cronica']+YRS
v6=v6[keep].rename(columns={'cuenca_canon':'cuenca'})
for y in YRS: v6[y]=pd.to_numeric(v6[y],errors='coerce').fillna(0).astype('int8')
u=f.merge(v6,left_on='ubigeo_limpio',right_on='ubigeo',how='left').drop(columns=['ubigeo'])

# --- impacto 2017 (por ubigeo) ---
imp=json.load(open('impacto2017.json',encoding='utf-8'))
impdf=pd.DataFrame([{'ub':k,'dmg17_dam':v['dam'],'dmg17_afe':v['afe'],'dmg17_viv':v['viv'],'dmg17_fall':v['fall']} for k,v in imp.items()])
u=u.merge(impdf,left_on='ubigeo_limpio',right_on='ub',how='left').drop(columns=['ub'])
for c in ['dmg17_dam','dmg17_afe','dmg17_viv','dmg17_fall']: u[c]=u[c].fillna(0).astype('int32')

# --- evidencia prensa (por ubigeo) ---
news=json.load(open('noticias.json',encoding='utf-8'))
ndf=pd.DataFrame([{'ub':k,'news_estado':v[0].get('estado',''),'news_url':v[0].get('url','')} for k,v in news.items() if v])
u=u.merge(ndf,left_on='ubigeo_limpio',right_on='ub',how='left').drop(columns=['ub'])
u['flg_prensa']=u['news_url'].notna().astype('int8')
u['news_estado']=u['news_estado'].fillna(''); u['news_url']=u['news_url'].fillna('')

# --- flags de decision PROPUESTOS (regla recomendada, NO final) ---
r45=u['R_nivel'].isin(['R4','R5'])
u['prop_target_castigo']=((u['prec_m']<=300)&(u['flg_ma_300']==1)&r45).astype('int8')
u['prop_alivio']=(r45&(u['flg_ma_1000']==0)).astype('int8')

OUT=SAL+'dataset_fen_cliente.parquet'
u.to_parquet(OUT,index=False)
nR=int(u['R_nivel'].notna().sum()); pctR=100*u['R_nivel'].notna().mean()
print('=== dataset_fen_cliente.parquet ===')
print('filas: {:,} | columnas: {}'.format(len(u),len(u.columns)))
print('R asignado: {:,} ({:.2f}%)'.format(nR,pctR))
print('con evidencia prensa (distrito): {:,}'.format(int(u['flg_prensa'].sum())))
print('activaron 2026 (a2026=1): {:,}'.format(int(u['a2026'].sum())))
print('prop_target_castigo: {:,} | prop_alivio: {:,}'.format(int(u['prop_target_castigo'].sum()),int(u['prop_alivio'].sum())))
print()
print('COLUMNAS ({}):'.format(len(u.columns)))
print(list(u.columns))
