# -*- coding: utf-8 -*-
# Version AUTOCONTENIDA: embebe PNGs y puntos lote en el HTML -> abre con doble clic, sin servidor.
import base64, json, os, glob
SAL='C:/Users/CARLOS/Downloads/Data_geo/Data_geo/data/salida/'
html=open(SAL+'mapa_fen2026_cuencas.html',encoding='utf-8').read()

# 1) inline PNGs (peligro + densidad)
for png in ['fen_max','fen_inund','fen_mm','ibk_300','ibk_500','ibk_1km','ibk_loc']:
    b64=base64.b64encode(open(SAL+png+'.png','rb').read()).decode()
    html=html.replace('src="'+png+'.png"','src="data:image/png;base64,'+b64+'"')
print('PNGs embebidos')

# 2) blob de puntos + indice
files=sorted(glob.glob(SAL+'ibk_pts/*.bin'))
blob=bytearray(); idx={}
for fp in files:
    ub=os.path.basename(fp)[:-4]
    data=open(fp,'rb').read()
    idx[ub]=[len(blob),len(data)]; blob+=data
b64=base64.b64encode(bytes(blob)).decode()
print('puntos:',len(files),'distritos |',round(len(blob)/1e6,1),'MB blob ->',round(len(b64)/1e6,1),'MB base64')
inject=('const __b=atob("'+b64+'");const __PTSBUF=new Uint8Array(__b.length);'
        'for(let _i=0;_i<__b.length;_i++)__PTSBUF[_i]=__b.charCodeAt(_i);'
        'const __PTSIDX='+json.dumps(idx,separators=(',',':'))+';')
html=html.replace('const OV=', inject+'const OV=', 1)

# 3) loadPts embebido (sin fetch)
OLD=("async function loadPts(ub){if(ub in _ptsCache)return _ptsCache[ub];try{const r=await fetch('ibk_pts/'+ub+'.bin');"
     "if(!r.ok){_ptsCache[ub]=null;return null;}const b=await r.arrayBuffer();const n=new DataView(b).getUint32(0,true);"
     "const o={n:n,col:new Float32Array(b,4,n),row:new Float32Array(b,4+n*4,n),tier:new Uint8Array(b,4+n*8,n)};"
     "_ptsCache[ub]=o;return o;}catch(e){_ptsCache[ub]=null;return null;}}")
NEW=("function loadPts(ub){if(ub in _ptsCache)return _ptsCache[ub];const ix=__PTSIDX[ub];if(!ix){_ptsCache[ub]=null;return null;}"
     "const b=__PTSBUF.buffer.slice(ix[0],ix[0]+ix[1]);const n=new DataView(b).getUint32(0,true);"
     "const o={n:n,col:new Float32Array(b,4,n),row:new Float32Array(b,4+n*4,n),tier:new Uint8Array(b,4+n*8,n)};"
     "_ptsCache[ub]=o;return o;}")
assert OLD in html, 'ERROR: no encontre loadPts para reemplazar'
html=html.replace(OLD,NEW)

out=SAL+'mapa_fen2026.html'
open(out,'w',encoding='utf-8').write(html)
print('escrito',out,'|',round(os.path.getsize(out)/1e6,1),'MB')
