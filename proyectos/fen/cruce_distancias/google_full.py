# -*- coding: utf-8 -*-
# Full Google rescue, RESUMABLE (checkpoint SQLite). Guarda crudo; el gate espacial se aplica al final.
import time, sqlite3
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import pandas as pd
from geopy.geocoders import GoogleV3

key=Path(r'C:\Users\CARLOS\Downloads\api_key_geo.txt').read_text(errors='ignore').strip().strip('"').strip()
geo=GoogleV3(api_key=key, timeout=30)
CACHE=r'C:\Users\CARLOS\AppData\Local\Temp\claude\C--Users-CARLOS\5b60f4b8-f5b9-45c4-a87d-fec71d90bd40\scratchpad\google_cache.sqlite'
CASC=r'C:/Users/CARLOS/Downloads/Data_geo/Data_geo/data/salida/geocodificado_cascada.parquet'

con=sqlite3.connect(CACHE)
con.execute('PRAGMA journal_mode=WAL')
con.execute('CREATE TABLE IF NOT EXISTS g (clave TEXT PRIMARY KEY, lon REAL, lat REAL, ltype TEXT, estado TEXT)')
con.commit()

def retry(q, tries=5):
    for t in range(tries):
        try: return geo.geocode(q), None
        except Exception as e:
            m=str(e)
            if t<tries-1 and any(x in m for x in ['OVER_QUERY_LIMIT','429','Temporarily','Connection']) or 'timed out' in m.lower():
                time.sleep(1.2*(2**t)); continue
            return None, m[:50]
    return None, 'retries'

def one(r):
    q=f"{r['direccion_limpia']}, {r['distrito_limpio']}, {r['provincia_limpio']}, {r['departamento_limpio']}, Peru"
    loc,err=retry(q)
    if err is not None: return (r['clave'],None,None,None,'error')
    if loc is None: return (r['clave'],None,None,None,'none')
    raw=loc.raw or {}
    return (r['clave'],loc.longitude,loc.latitude,raw.get('geometry',{}).get('location_type'),'ok')

df=pd.read_parquet(CASC, columns=['clave','direccion_limpia','distrito_limpio','provincia_limpio','departamento_limpio','estado_cascada'])
cand=df[df['estado_cascada']=='candidato_google']
done=set(x[0] for x in con.execute('SELECT clave FROM g'))
pend=cand[~cand['clave'].isin(done)].to_dict('records')
print(f'candidatos {len(cand):,} | ya en cache {len(done):,} | pendientes {len(pend):,}', flush=True)

CHUNK=500; t0=time.time(); n=0
with ThreadPoolExecutor(max_workers=6) as ex:
    for i in range(0,len(pend),CHUNK):
        for res in ex.map(one, pend[i:i+CHUNK]):
            con.execute('INSERT OR REPLACE INTO g VALUES (?,?,?,?,?)', res); n+=1
        con.commit()
        el=time.time()-t0; rate=n/max(el,1e-6); eta=(len(pend)-n)/max(rate,1e-6)/3600
        print(f'{n:,}/{len(pend):,} | {rate:.1f} req/s | ETA {eta:.1f}h | ~${(len(done)+n)*5/1000:,.0f}', flush=True)
con.commit(); con.close()
print('=== FULL GOOGLE TERMINADO ===', flush=True)
