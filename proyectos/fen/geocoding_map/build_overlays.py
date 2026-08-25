# -*- coding: utf-8 -*-
import geopandas as gpd, pandas as pd, json, os
G='C:/Users/CARLOS/elnino_ibk/01_inputs/geo/'
susc=gpd.read_file('cenepred/Shape/susc_mmasa_pp.shp')
xmin,ymin,xmax,ymax=susc.total_bounds; res=550.0
W=int((xmax-xmin)/res); H=int((ymax-ymin)/res)
print(f'grid {W}x{H}', flush=True)

def rings(geom, simp):
    geom=geom.simplify(simp, preserve_topology=True)
    polys=[geom] if geom.geom_type=='Polygon' else list(geom.geoms)
    out=[]
    for p in polys:
        for ring in [p.exterior]+list(p.interiors):
            xs,ys=ring.coords.xy; d=''
            for i,(x,y) in enumerate(zip(xs,ys)):
                d+=('M' if i==0 else 'L')+f'{(x-xmin)/res:.0f} {(ymax-y)/res:.0f}'
            out.append(d+'Z')
    return out

def process(path, simp, pac_only):
    g=gpd.read_file(path)
    if pac_only: g=g[g['NOMB_UH_N1'].str.contains('Pac',na=False)]
    g=g.to_crs('EPSG:32718'); feats=[]
    for _,r in g.iterrows():
        try: paths=rings(r.geometry, simp)
        except Exception: continue
        feats.append({'d':' '.join(paths)})
    return feats

cue=process(G+'cuencas.geojson', 800, True)
sub=process(G+'uh_ana_nivel7.geojson', 600, True)

# distritos con ficha FEN (grado_fen_v6 = vigente, incluye evento 2026)
fen=pd.read_csv('C:/Users/CARLOS/elnino_ibk/02_pipeline/out/grado_fen_v6.csv',dtype=str)
fen=fen.drop_duplicates('ubigeo').set_index('ubigeo')
IMP=json.load(open('impacto2017.json',encoding='utf-8')) if os.path.exists('impacto2017.json') else {}
NEWS=json.load(open('noticias.json',encoding='utf-8')) if os.path.exists('noticias.json') else {}
YRS=['a1983','a1987','a1992','a1998','a2016','a2017','a2023','a2024','a2026']
def sval(row,k):
    v=row.get(k)
    if v is None: return ''
    try:
        import math
        if isinstance(v,float) and math.isnan(v): return ''
    except Exception: pass
    s=str(v).strip(); return '' if s.lower()=='nan' else s
dg=gpd.read_file(G+'peru_dist.geojson').to_crs('EPSG:32718')
dist=[]; nfen=0
for _,r in dg.iterrows():
    try: paths=rings(r.geometry, 300)
    except Exception: continue
    rp=r.geometry.representative_point()
    u=str(r['IDDIST'])
    f={'d':' '.join(paths),'name':str(r['NOMBDIST']).strip(),
       'lx':round((rp.x-xmin)/res),'ly':round((ymax-rp.y)/res),
       'ub':u,'pr':str(r['NOMBPROV']).strip(),'dp':str(r['NOMBDEP']).strip()}
    if u in fen.index:
        row=fen.loc[u]; nfen+=1
        f['R']=sval(row,'R_nivel')
        f['cu']=sval(row,'cuenca') or sval(row,'cuenca_canon')
        f['pac']=sval(row,'pacifico'); f['ne']=sval(row,'n_eventos')
        f['pe']=sval(row,'pct_expuesto'); f['pat']=sval(row,'patron_evento')
        f['sev']=sval(row,'sev'); f['rec']=sval(row,'rec'); f['fra']=sval(row,'fra')
        f['exn']=sval(row,'exp_n'); f['sc']=sval(row,'score')
        f['yr']=[y[1:] for y in YRS if sval(row,y)=='1']
    if u in IMP: f['im']=IMP[u]
    if u in NEWS: f['news']=NEWS[u]
    dist.append(f)
print(f'distritos {len(dist)} | con ficha FEN {nfen}')

data={'W':W,'H':H,'cuencas':cue,'subcuencas':sub,'distritos':dist}
if os.path.exists('overlays.json'):
    old=json.load(open('overlays.json',encoding='utf-8'))
    for k in ['cotas','cota_leg']:
        if k in old: data[k]=old[k]
open('overlays.json','w',encoding='utf-8').write(json.dumps(data,ensure_ascii=False,separators=(',',':')))
print(f'cuencas {len(cue)} | subcuencas {len(sub)} | cotas: {"cotas" in data}')
print('overlays.json', round(os.path.getsize('overlays.json')/1024),'KB')
