'use strict';
const fs=require('fs');
const M=fs.readFileSync(__dirname+'/_slidemap_v3.json','utf8');
const dist=JSON.parse(M).feats.reduce((a,f)=>{a[f.r]=(a[f.r]||0)+1;return a;},{});
const COL=['#e2e8ee','#ffe2a8','#ffbf6b','#fb8c3c','#ed5a25','#b81e16'];
const LAB=['R0 — No expuesto / no-Pacífico','R1 — Marginal','R2 — Bajo','R3 — Medio','R4 — Alto','R5 — Crítico'];
const legend=COL.map((c,i)=>`<div class="lg"><span class="sw" style="background:${c}"></span><b>${['R0','R1','R2','R3','R4','R5'][i]}</b><span class="lt">${LAB[i].split('— ')[1]}</span><span class="ln">${(dist[i]||0)}</span></div>`).join('');
const html=`<!DOCTYPE html><html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Mapa FEN por distrito — Taxonomía R0–R5</title>
<link href="https://fonts.googleapis.com/css2?family=Archivo:wght@400;600;800&family=Spline+Sans:wght@400;500;600&display=swap" rel="stylesheet">
<style>
:root{--navy:#0e2a47;--green:#00A94F;--ink:#13202e;--mut:#5b6b7c;--line:#e3e9ef;--bg:#f5f7fa}
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:'Spline Sans',system-ui,sans-serif;background:var(--bg);color:var(--ink);padding:28px 34px}
.head{display:flex;align-items:flex-end;justify-content:space-between;border-bottom:3px solid var(--navy);padding-bottom:14px;margin-bottom:18px}
h1{font-family:'Archivo',sans-serif;font-weight:800;font-size:30px;color:var(--navy);letter-spacing:-.5px}
.sub{font-size:14px;color:var(--mut);margin-top:4px}
.tag{font-family:'Archivo';font-weight:800;font-size:13px;color:#fff;background:var(--green);padding:6px 12px;border-radius:6px;letter-spacing:.5px}
.wrap{display:grid;grid-template-columns:560px 1fr;gap:34px;align-items:start}
.mapbox{background:#fff;border:1px solid var(--line);border-radius:12px;padding:10px;box-shadow:0 2px 14px rgba(14,42,71,.06)}
svg{width:100%;height:auto;display:block}
path{stroke:#fff;stroke-width:.25;cursor:pointer;transition:opacity .1s}
path:hover{stroke:var(--navy);stroke-width:1.1}
.side{padding-top:6px}
.panel{background:#fff;border:1px solid var(--line);border-radius:12px;padding:20px 22px;margin-bottom:18px;box-shadow:0 2px 14px rgba(14,42,71,.06)}
.panel h2{font-family:'Archivo';font-weight:800;font-size:15px;color:var(--navy);text-transform:uppercase;letter-spacing:.6px;margin-bottom:14px}
.lg{display:grid;grid-template-columns:22px 38px 1fr 56px;align-items:center;gap:10px;padding:7px 0;border-bottom:1px solid var(--line);font-size:14px}
.lg:last-child{border-bottom:0}
.sw{width:18px;height:18px;border-radius:4px;border:1px solid rgba(0,0,0,.12)}
.lg b{font-family:'Archivo';font-weight:800;color:var(--ink)}
.lt{color:var(--mut)}
.ln{text-align:right;font-weight:600;font-variant-numeric:tabular-nums;color:var(--navy)}
.note{font-size:12.5px;color:var(--mut);line-height:1.55;margin-top:8px}
.kpi{display:flex;gap:14px;margin-top:6px}
.kpi .b{flex:1;background:linear-gradient(180deg,#f8fafc,#eef3f8);border:1px solid var(--line);border-radius:10px;padding:14px}
.kpi .n{font-family:'Archivo';font-weight:800;font-size:26px;color:var(--navy)}
.kpi .l{font-size:12px;color:var(--mut);margin-top:2px}
#tip{position:fixed;pointer-events:none;background:var(--navy);color:#fff;padding:8px 11px;border-radius:7px;font-size:12.5px;opacity:0;transition:opacity .08s;z-index:9;box-shadow:0 4px 16px rgba(0,0,0,.25);max-width:240px}
#tip b{font-family:'Archivo';font-weight:800}
#tip .r{display:inline-block;padding:1px 7px;border-radius:4px;color:#13202e;font-weight:700;margin-top:4px}
</style></head><body>
<div class="head"><div><h1>Exposición a El Niño costero (FEN) por distrito</h1>
<div class="sub">Taxonomía ordinal R0–R5 · score = severidad + recurrencia + fragilidad + exposición · 1,826 distritos mapeados (de 1,890)</div></div>
<div class="tag">CLASIFICACIÓN FINAL</div></div>
<div class="wrap">
 <div class="mapbox"><svg id="map" viewBox="0 0 540 820" aria-label="Mapa de distritos del Perú coloreados por nivel FEN"></svg></div>
 <div class="side">
  <div class="panel"><h2>Niveles (n distritos)</h2>${legend}
   <div class="note">R0 agrupa los distritos no-Pacífico (sin gate El Niño costero). R1–R5 resultan de cortes naturales de Fisher-Jenks sobre el score continuo de los distritos del Pacífico.</div></div>
  <div class="panel"><h2>Núcleo crítico</h2>
   <div class="kpi"><div class="b"><div class="n">${(dist[4]||0)+(dist[5]||0)}</div><div class="l">distritos R4+R5</div></div>
   <div class="b"><div class="n">${dist[5]||0}</div><div class="l">distritos R5 (crítico)</div></div></div>
   <div class="note">R4+R5 concentran el impacto FEN observado: en Stock TC, +3–4pp de RD sobre el baseline en la ventana El Niño 2023, y ~15% de la cartera.</div></div>
 </div>
</div>
<div id="tip"></div>
<script>
const MAP=${M};
const COL=${JSON.stringify(COL)};
const RL=['R0','R1','R2','R3','R4','R5'];
const svg=document.getElementById('map');
let html='';
MAP.feats.forEach((f,i)=>{html+='<path d="'+f.d+'" fill="'+COL[f.r]+'" data-i="'+i+'"></path>';});
svg.innerHTML=html;
const tip=document.getElementById('tip');
svg.addEventListener('mousemove',e=>{const t=e.target;if(t.tagName!=='path'){tip.style.opacity=0;return;}
 const f=MAP.feats[+t.getAttribute('data-i')];if(!f.nm){tip.style.opacity=0;return;}
 tip.innerHTML='<b>'+f.nm+'</b><br><span class="r" style="background:'+COL[f.r]+'">'+RL[f.r]+'</span> · score '+f.sc+' · exp '+f.p+'%';
 tip.style.left=(e.clientX+14)+'px';tip.style.top=(e.clientY+14)+'px';tip.style.opacity=1;});
svg.addEventListener('mouseleave',()=>tip.style.opacity=0);
</script></body></html>`;
fs.writeFileSync(__dirname+'/mapa_fen_v3.html',html,'utf8');
console.log('mapa_fen_v3.html | KB:',(fs.statSync(__dirname+'/mapa_fen_v3.html').size/1024).toFixed(0),'| R0..R5:',JSON.stringify(dist));
