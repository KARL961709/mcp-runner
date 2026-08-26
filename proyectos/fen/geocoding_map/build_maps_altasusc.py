# -*- coding: utf-8 -*-
import base64, os
D=r'C:/Users/CARLOS/Downloads/Data_geo/Data_geo/data/salida/'
def b(f): return base64.b64encode(open(D+f,'rb').read()).decode()
# peligro (fen_*) y capas IBK se sirven como archivos externos, no embebidos (pesan al ser finos)
OV=open('overlays.json',encoding='utf-8').read()
ST=open('dist_stats.json',encoding='utf-8').read() if os.path.exists('dist_stats.json') else '{}'
HTML=r'''<!DOCTYPE html><html lang="es" data-theme="dark"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>FEN 2026 - Altamente susceptible</title>
<link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,700;12..96,800&family=Public+Sans:wght@400;500;600&family=IBM+Plex+Mono:wght@400;600&display=swap">
<style>
:root{--bg:#eef1f4;--panel:#fff;--ink:#182430;--muted:#5b6a79;--line:#dce2e8;--accent:#00a94f;--z:100%;--shadow:0 2px 12px rgba(24,36,48,.10);}
@media (prefers-color-scheme:dark){:root:not([data-theme=light]){--bg:#0a0e13;--panel:#131b24;--ink:#e9eef4;--muted:#8a99aa;--line:#212d38;--accent:#12bd6b;--shadow:0 8px 28px rgba(0,0,0,.55);}}
:root[data-theme=dark]{--bg:#0a0e13;--panel:#131b24;--ink:#e9eef4;--muted:#8a99aa;--line:#212d38;--accent:#12bd6b;--shadow:0 8px 28px rgba(0,0,0,.55);}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font-family:"Public Sans",system-ui,sans-serif}
header{position:fixed;top:0;left:0;right:0;z-index:20;padding:11px 16px;border-bottom:1px solid var(--line);background:var(--panel);display:flex;align-items:center;gap:10px;flex-wrap:wrap}
.eyebrow{font:600 10px/1 "IBM Plex Mono",monospace;letter-spacing:.14em;text-transform:uppercase;color:var(--accent)}
h1{font-family:"Bricolage Grotesque",sans-serif;font-weight:800;font-size:16px;margin:2px 0 0;letter-spacing:-.01em}
.seg{display:flex;background:var(--bg);border:1px solid var(--line);border-radius:9px;padding:3px;gap:3px}
.seg button{border:0;background:transparent;color:var(--muted);cursor:pointer;font:600 11.5px "Public Sans";padding:7px 10px;border-radius:6px;white-space:nowrap}
.seg button[aria-pressed=true]{background:var(--accent);color:#fff}
.tgl{display:flex;gap:5px;flex-wrap:wrap}
.tgl button{border:1px solid var(--line);background:var(--panel);color:var(--muted);cursor:pointer;font:600 11px "Public Sans";padding:6px 9px;border-radius:8px;display:flex;align-items:center;gap:5px}
.tgl button[aria-pressed=true]{color:var(--ink);border-color:var(--accent)}
.tgl .dot{width:11px;height:4px;border-radius:2px;display:inline-block}
.leg{display:flex;gap:9px;align-items:center;flex-wrap:wrap}
.chip{display:flex;align-items:center;gap:5px;font-size:11px;font-weight:500}.chip.mut{color:var(--muted)}
.sw{width:12px;height:12px;border-radius:4px;border:1px solid rgba(0,0,0,.15)}
.ctr{display:flex;gap:6px;margin-left:auto}.ctr button{border:1px solid var(--line);background:var(--panel);color:var(--ink);cursor:pointer;font:600 14px "Public Sans";min-width:34px;height:34px;padding:0 9px;border-radius:8px}
.ctr button:hover{border-color:var(--accent);color:var(--accent)}
.stage{padding:16px;text-align:left}
.frame{position:relative;display:inline-block;width:var(--z);max-width:none;vertical-align:top}
.frame img{width:100%;height:auto;display:none;border-radius:8px;box-shadow:var(--shadow);background:var(--panel)}
.frame img.on{display:block}
.frame svg{position:absolute;inset:0;width:100%;height:100%;pointer-events:none}
.frame svg.off{display:none}
.frame .ovimg{position:absolute;top:0;left:0;width:100%;height:auto;display:block;pointer-events:none;box-shadow:none;background:none}
.frame .ovimg.off{display:none}
.frame canvas{position:absolute;pointer-events:none;display:none;image-rendering:auto}
svg .sc{fill:none;stroke:#5b9bd8;stroke-width:1.1;vector-effect:non-scaling-stroke}
svg .cc{fill:none;stroke:#5b9bd8;stroke-width:1.1;vector-effect:non-scaling-stroke}
svg .ct{fill:none;stroke-width:.55;vector-effect:non-scaling-stroke;opacity:.8}
svg .dc{fill:none;stroke:#7c8a9b;stroke-width:.85;opacity:.85;vector-effect:non-scaling-stroke}
svg .dlbl{fill:#dbe6ef;font-family:"IBM Plex Mono",monospace;font-weight:500;font-size:var(--lblf,10px);paint-order:stroke;stroke:#0c1319;stroke-width:calc(var(--lblf,10px)/4);text-anchor:middle;letter-spacing:-.2px}
svg#ovDist.nolbl text{display:none}
svg .selp{fill:rgba(74,222,128,.13);stroke:#4ade80;stroke-width:3;vector-effect:non-scaling-stroke}
svg .sellbl{fill:#ecfff5;font:700 var(--sellf,16px) "IBM Plex Mono",monospace;paint-order:stroke;stroke:#06210f;stroke-width:calc(var(--sellf,16px)/3.5);text-anchor:middle}
.finder{display:flex;align-items:center;gap:5px;background:var(--bg);border:1px solid var(--line);border-radius:9px;padding:3px 3px 3px 9px}
.finder svg{width:14px;height:14px;flex:0 0 auto;opacity:.6}
.finder input{border:0;background:transparent;color:var(--ink);font:500 12px "Public Sans";width:190px;outline:none}
.finder button{border:0;background:transparent;color:var(--muted);cursor:pointer;font:700 14px "Public Sans";width:24px;height:24px;border-radius:6px}
.finder button:hover{color:var(--accent)}
.casc{display:flex;gap:5px;flex-wrap:wrap}
.casc select{border:1px solid var(--line);background:var(--panel);color:var(--ink);font:500 11.5px "Public Sans";padding:6px 7px;border-radius:8px;max-width:155px;cursor:pointer}
.casc select:disabled{opacity:.45;cursor:default}
.rfilter{display:flex;gap:4px;align-items:center;flex-wrap:wrap}
.rfilter .lb{font:600 9px "IBM Plex Mono",monospace;color:var(--muted);text-transform:uppercase;letter-spacing:.05em;margin-right:1px}
.rfilter button{border:1px solid var(--line);background:var(--panel);color:var(--muted);cursor:pointer;font:700 10.5px "IBM Plex Mono",monospace;padding:5px 7px;border-radius:7px;min-width:29px}
.rfilter button[aria-pressed=true]{color:#fff!important;border-color:transparent}
.card{position:fixed;left:16px;bottom:16px;z-index:9;width:290px;max-width:calc(100vw - 32px);max-height:calc(100vh - 32px);overflow:auto;background:var(--panel);border:1px solid var(--line);border-radius:14px;box-shadow:var(--shadow);padding:14px 15px;display:none}
.card.on{display:block}
.card{scrollbar-width:thin;scrollbar-color:var(--line) transparent}
.card::-webkit-scrollbar{width:8px}
.card::-webkit-scrollbar-thumb{background:var(--line);border-radius:4px}
.card::-webkit-scrollbar-track{background:transparent}
@media (max-height:880px){.card{padding:11px 12px}.card h3{font-size:15px;margin-bottom:1px}.card .sub{margin-bottom:7px}.sctitle{margin-top:2px;margin-bottom:4px}.sc{margin-bottom:8px}.imp{margin-bottom:5px}.impnote{margin-bottom:8px}.kv{margin-bottom:8px}.cleg2{margin-bottom:8px}.yrs{margin-top:3px}.rbadge{margin-bottom:8px}}
@media (max-height:720px){.card{padding:9px 11px;border-radius:11px}.card h3{font-size:13.5px}.scrow b,.kv{font-size:10.5px}.rbadge{padding:4px 9px;font-size:12px}}
.card .x{position:absolute;top:9px;right:10px;border:0;background:transparent;color:var(--muted);cursor:pointer;font:700 16px "Public Sans"}
.card .mn{position:absolute;top:7px;right:32px;border:0;background:transparent;color:var(--muted);cursor:pointer;font:700 19px "Public Sans";line-height:1;padding:0 3px}
.card .x:hover,.card .mn:hover{color:var(--accent)}
.card.min > *{display:none}
.card.min > button,.card.min > h3,.card.min > .sub,.card.min > #cR{display:block}
.card.min > h3{margin-bottom:2px}.card.min > #cR{margin-bottom:0}
.card h3{font-family:"Bricolage Grotesque",sans-serif;font-weight:800;font-size:17px;margin:0 22px 1px 0;letter-spacing:-.01em}
.card .sub{color:var(--muted);font-size:11.5px;margin-bottom:11px}
.rbadge{display:inline-flex;align-items:center;gap:7px;padding:6px 11px;border-radius:9px;font:700 13px "Public Sans";color:#fff;margin-bottom:11px}
.sctitle{font:600 10px "IBM Plex Mono",monospace;letter-spacing:.08em;text-transform:uppercase;color:var(--muted);margin:2px 0 5px}
.sc{margin-bottom:11px}
.scrow{display:grid;grid-template-columns:76px 1fr 40px;align-items:center;gap:8px;margin:4px 0}
.scrow b{color:var(--ink);font-weight:500;font-size:11px}
.scbar{height:6px;border-radius:3px;background:var(--line);overflow:hidden}
.scbar i{display:block;height:100%;border-radius:3px}
.scrow em{text-align:right;font:600 10.5px "IBM Plex Mono",monospace;font-style:normal;color:var(--muted)}
.scrow.tot{margin-top:6px;padding-top:6px;border-top:1px solid var(--line)}
.scrow.tot b{font-weight:700}.scrow.tot em{color:var(--ink)}
.kv{display:grid;grid-template-columns:auto 1fr;gap:3px 10px;font-size:12px;margin-bottom:10px}
.kv b{color:var(--muted);font-weight:600}
.yrs{display:flex;gap:4px;flex-wrap:wrap}
.yrs span{font:600 10px "IBM Plex Mono",monospace;padding:3px 5px;border-radius:5px;border:1px solid var(--line);color:var(--muted)}
.yrs span.hit{background:#ec7038;border-color:#ec7038;color:#fff}
.imp{display:flex;gap:6px;flex-wrap:wrap;margin-bottom:6px}
.imp .st{flex:1 1 auto;min-width:70px;background:var(--bg);border:1px solid var(--line);border-radius:9px;padding:6px 8px}
.imp .st b{display:block;font:800 15px "Bricolage Grotesque",sans-serif;color:var(--ink);line-height:1.1}
.imp .st span{font:600 8.5px "IBM Plex Mono",monospace;letter-spacing:.03em;text-transform:uppercase;color:var(--muted)}
.impnote{font-size:10.5px;color:var(--muted);margin:0 0 11px;line-height:1.35}
.impnote b{color:var(--ink);font-weight:600}
.ccov{font-size:11.5px;margin-bottom:6px}.ccov b{color:var(--muted);font-weight:600}
.cbar{display:flex;height:10px;border-radius:5px;overflow:hidden;background:var(--line);margin-bottom:6px}
.cbar i{display:block;height:100%}
.cleg2{display:flex;gap:9px;flex-wrap:wrap;font-size:10.5px;color:var(--muted);margin-bottom:11px}
.cleg2 .d{display:inline-block;width:9px;height:9px;border-radius:2px;margin-right:3px;vertical-align:middle}
.news{display:flex;flex-direction:column;gap:7px;margin-top:5px}
.news .it{background:var(--bg);border:1px solid var(--line);border-radius:9px;padding:8px 9px}
.news .tag{display:inline-block;font:700 8.5px "IBM Plex Mono",monospace;letter-spacing:.03em;padding:2px 6px;border-radius:5px;background:var(--accent);color:#fff;margin-bottom:5px}
.news p{margin:0 0 5px;font-size:11px;line-height:1.4;color:var(--ink)}
.news a{font:600 10.5px "Public Sans";color:var(--accent);text-decoration:none;word-break:break-word}
.news a:hover{text-decoration:underline}
.precp{position:fixed;right:16px;top:120px;z-index:9;width:262px;max-width:calc(100vw - 32px);background:var(--panel);border:1px solid var(--line);border-radius:12px;box-shadow:var(--shadow);padding:12px 13px;display:none}
.precp.on{display:block}
.precp h4{font-family:"Bricolage Grotesque",sans-serif;font-weight:800;font-size:12.5px;margin:0 0 8px}
.precp table{width:100%;border-collapse:collapse;font-size:11px}
.precp th{text-align:left;color:var(--muted);font:600 8.5px "IBM Plex Mono",monospace;letter-spacing:.03em;text-transform:uppercase;padding-bottom:5px;border-bottom:1px solid var(--line)}
.precp th:nth-child(2),.precp th:nth-child(3){text-align:right}
.precp td{padding:4px 2px;border-bottom:1px solid var(--line);color:var(--ink)}
.precp td:nth-child(2),.precp td:nth-child(3){text-align:right;font:600 10.5px "IBM Plex Mono",monospace}
.precp tr.act td{background:rgba(0,177,80,.16);font-weight:700}
.precp tr.actL td{background:rgba(155,89,182,.18);font-weight:700}
.precp tr.tot td{border-top:2px solid var(--line);border-bottom:none;font-weight:700;color:var(--ink)}
.note{color:var(--muted);font-size:11px;text-align:center;padding:8px 20px 8px;max-width:900px;margin:0 auto}
.legbar{position:fixed;left:50%;bottom:12px;transform:translateX(-50%);z-index:8;display:inline-flex;gap:8px;align-items:center;flex-wrap:wrap;justify-content:center;background:var(--panel);border:1px solid var(--line);border-radius:11px;padding:8px 14px;box-shadow:var(--shadow);max-width:calc(100vw - 32px)}
.legbar .sw{border:1px solid rgba(255,255,255,.18)}
</style></head><body>
<header>
<div><div class="eyebrow">CENEPRED 25-27 · Cuencas ANA · Curvas de nivel</div><h1>FEN 2026 · Altamente susceptible</h1></div>
<div class="seg" role="group" style="display:none"><button id="bMX" aria-pressed="true">Unificado</button><button id="bIN">Inundacion</button><button id="bMM">Mov. masa</button></div>
<div class="tgl">
<button id="tCue" aria-pressed="true"><span class="dot" style="background:#5b9bd8"></span>Cuencas</button>
<button id="tSub"><span class="dot" style="background:#5b9bd8;opacity:.6"></span>Subcuencas</button>
<button id="tCot"><span class="dot" style="background:linear-gradient(90deg,#3c9650,#dcbe5f,#6e4630)"></span>Curvas de nivel</button>
<button id="tDis" aria-pressed="true"><span class="dot" style="background:#7c8a9b"></span>Distritos</button>
<button id="tI3"><span class="dot" style="background:#00b150"></span>IBK &le;300m</button>
<button id="tI5"><span class="dot" style="background:#00b150;opacity:.7"></span>IBK &le;500m</button>
<button id="tI1"><span class="dot" style="background:#00b150;opacity:.45"></span>IBK &le;1km</button>
<button id="tIL"><span class="dot" style="background:#9b59b6"></span>IBK &gt;1km</button>
<button id="tPts"><span class="dot" style="background:#0a7d3a"></span>Puntos (lote)</button>
</div>
<div class="finder">
<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4"><circle cx="11" cy="11" r="7"/><path d="M21 21l-4.3-4.3"/></svg>
<input id="find" list="distlist" placeholder="Buscar distrito..." autocomplete="off">
<button id="findx" title="Limpiar">&times;</button>
</div>
<datalist id="distlist"></datalist>
<div class="casc">
<select id="selDep"><option value="">Departamento…</option></select>
<select id="selProv" disabled><option value="">Provincia…</option></select>
<select id="selDist" disabled><option value="">Distrito…</option></select>
</div>
<div class="rfilter"><span class="lb">Score FEN</span><button class="rf" data-r="R0">R0</button><button class="rf" data-r="R1">R1</button><button class="rf" data-r="R2">R2</button><button class="rf" data-r="R3">R3</button><button class="rf" data-r="R4">R4</button><button class="rf" data-r="R5">R5</button></div>
<div class="ctr"><button id="zo">-</button><button id="rs">100%</button><button id="zi">+</button></div>
</header>
<div class="stage"><div class="frame" id="frame">
<img id="imMX" class="on" src="fen_altasusc.png" alt="Altamente susceptible">
<img id="imIN" src="fen_altasusc.png" alt="Altamente susceptible">
<img id="imMM" src="fen_altasusc.png" alt="Altamente susceptible">
<img id="ibk300" class="ovimg off" src="ibk_300.png" alt="IBK <=300m">
<img id="ibk500" class="ovimg off" src="ibk_500.png" alt="IBK <=500m">
<img id="ibk1km" class="ovimg off" src="ibk_1km.png" alt="IBK <=1km">
<img id="ibkloc" class="ovimg off" src="ibk_loc.png" alt="IBK >1km">
<svg id="ovCotas" class="off"></svg><svg id="ovDist"></svg><svg id="ovSub" class="off"></svg><svg id="ovCue"></svg><svg id="ovSel"></svg><canvas id="ovPts"></canvas>
</div></div>
<div class="card" id="card"><button class="x" id="cardx">&times;</button><button class="mn" id="cardmin" title="Minimizar">–</button>
<h3 id="cName"></h3><div class="sub" id="cSub"></div>
<div id="cR"></div>
<div class="sctitle">Componentes del score</div><div class="sc" id="cScore"></div>
<div class="sctitle" id="cCompT">Composición direcciones (≤300m)</div><div id="cComp"></div>
<div class="sctitle" id="cImpT">Impacto El Niño 2017 (SINPAD)</div>
<div class="imp" id="cImp"></div>
<div class="impnote" id="cImpNote">La <b>severidad</b> del score se construye con <b>damnificados</b> (perdieron vivienda), no con afectados: máx(propio&nbsp;2017, cuenca) normalizado.</div>
<div class="kv" id="cKv"></div>
<div><b style="color:var(--muted);font-size:11px;font-weight:600">Eventos El Nino registrados</b><div class="yrs" id="cYrs"></div></div>
<div class="sctitle" id="cNewsT" style="margin-top:11px">Evidencia en prensa</div>
<div class="news" id="cNews"></div>
</div>
<div class="precp" id="precp">
<h4>Precisión de direcciones IBK</h4>
<table><thead><tr><th>Precisión</th><th>Registros</th><th>%</th></tr></thead><tbody>
<tr id="row_t3"><td>&le; 300 m</td><td>1 228 191</td><td>70.70%</td></tr>
<tr id="row_t5"><td>&le; 500 m</td><td>1 229 573</td><td>70.78%</td></tr>
<tr id="row_t1"><td>&le; 1 km</td><td>1 229 573</td><td>70.78%</td></tr>
<tr id="row_tL"><td>&gt; 1 km (localidad)</td><td>507 516</td><td>29.22%</td></tr>
<tr class="tot"><td>Total</td><td>1 737 123</td><td>100%</td></tr>
</tbody></table></div>
<p class="note" id="note"></p>
<div class="legbar"><span class="leg" id="pleg" style="justify-content:center;display:inline-flex"></span> &nbsp;·&nbsp; <span class="leg" id="cleg" style="justify-content:center;display:inline-flex"></span></div>
<script>
const OV=__OV__;
const STATS=__ST__;
const LEG={MX:[['#AE1A1A','Altamente susceptible']],IN:[['#AE1A1A','Altamente susceptible']],MM:[['#AE1A1A','Altamente susceptible']]};
const NOTE={MX:'Altamente susceptible = peligro MUY ALTO del escenario unificado (MAX inundacion, mov. masa) CENEPRED, vertiente Pacifico. Rojo = altamente susceptible; gris = resto. Lineas azules = cuencas ANA. Los nombres de distrito aparecen al acercar el zoom.',IN:'Altamente susceptible (unificado).',MM:'Altamente susceptible (unificado).'};
const IMG={MX:'imMX',IN:'imIN',MM:'imMM'};const NS='http://www.w3.org/2000/svg';
function build(){const cue=document.getElementById('ovCue'),sub=document.getElementById('ovSub'),cot=document.getElementById('ovCotas'),dis=document.getElementById('ovDist'),sel=document.getElementById('ovSel');const vb='0 0 '+OV.W+' '+OV.H;
 for(const s of [cue,sub,cot,dis,sel]){s.setAttribute('viewBox',vb);s.setAttribute('preserveAspectRatio','none');}
 for(const f of OV.subcuencas){const p=document.createElementNS(NS,'path');p.setAttribute('d',f.d);p.setAttribute('class','sc');sub.appendChild(p);}
 for(const f of OV.cuencas){const p=document.createElementNS(NS,'path');p.setAttribute('d',f.d);p.setAttribute('class','cc');cue.appendChild(p);}
 for(const f of (OV.distritos||[])){const p=document.createElementNS(NS,'path');p.setAttribute('d',f.d);p.setAttribute('class','dc');dis.appendChild(p);}
 for(const f of (OV.distritos||[])){if(!f.name)continue;const t=document.createElementNS(NS,'text');t.setAttribute('x',f.lx);t.setAttribute('y',f.ly);t.setAttribute('class','dlbl');t.textContent=f.name;dis.appendChild(t);}
 for(const f of (OV.cotas||[])){const p=document.createElementNS(NS,'path');p.setAttribute('d',f.d);p.setAttribute('class','ct');p.setAttribute('stroke',f.c);cot.appendChild(p);}
 if(OV.cota_leg)document.getElementById('cleg').innerHTML='<span class="chip mut">Curva (m):</span>'+OV.cota_leg.map(x=>'<span class="chip"><span class="dot" style="width:13px;height:3px;background:'+x[0]+'"></span>'+x[1]+'</span>').join('');}
let cur='MX',z=100;const root=document.documentElement;
function draw(){for(const k in IMG)document.getElementById(IMG[k]).classList.toggle('on',k===cur);
 for(const k of ['MX','IN','MM'])document.getElementById('b'+k).setAttribute('aria-pressed',k===cur);
 document.getElementById('pleg').innerHTML='<span class="chip mut">Peligro:</span>'+LEG[cur].map(x=>'<span class="chip"><span class="sw" style="background:'+x[0]+'"></span>'+x[1]+'</span>').join('');
 document.getElementById('note').textContent=NOTE[cur];}
function relabel(){const dis=document.getElementById('ovDist');const fw=document.getElementById('frame').getBoundingClientRect().width;if(fw>0)dis.style.setProperty('--lblf',(12*OV.W/fw)+'px');dis.classList.toggle('nolbl',z<160);}
function setZ(v){z=Math.max(40,Math.min(18000,Math.round(v)));root.style.setProperty('--z',z+'%');document.getElementById('rs').textContent=z+'%';relabel();}
for(const k of ['MX','IN','MM'])document.getElementById('b'+k).onclick=()=>{cur=k;draw();};
function tog(btn,el){const b=document.getElementById(btn);const on=b.getAttribute('aria-pressed')!=='true';b.setAttribute('aria-pressed',on);document.getElementById(el).classList.toggle('off',!on);}
document.getElementById('tCue').onclick=()=>tog('tCue','ovCue');
document.getElementById('tSub').onclick=()=>tog('tSub','ovSub');
document.getElementById('tCot').onclick=()=>tog('tCot','ovCotas');
document.getElementById('tDis').onclick=()=>tog('tDis','ovDist');
function isOn(id){return document.getElementById(id).getAttribute('aria-pressed')==='true';}
function updatePrec(){const on={t3:isOn('tI3'),t5:isOn('tI5'),t1:isOn('tI1'),tL:isOn('tIL')};
 document.getElementById('precp').classList.toggle('on',on.t3||on.t5||on.t1||on.tL);
 for(const k of ['t3','t5','t1','tL']){const r=document.getElementById('row_'+k);if(r)r.className=on[k]?(k==='tL'?'actL':'act'):'';}}
function togIbk(btn,el){tog(btn,el);updatePrec();if(isOn('tPts')&&curFeat)drawPtsFor(curFeat);}
document.getElementById('tI3').onclick=()=>togIbk('tI3','ibk300');
document.getElementById('tI5').onclick=()=>togIbk('tI5','ibk500');
document.getElementById('tI1').onclick=()=>togIbk('tI1','ibk1km');
document.getElementById('tIL').onclick=()=>togIbk('tIL','ibkloc');
document.getElementById('tPts').onclick=()=>{const b=document.getElementById('tPts');const on=b.getAttribute('aria-pressed')!=='true';b.setAttribute('aria-pressed',on);if(on&&curFeat)drawPtsFor(curFeat);else hidePts();};
function zoomAt(factor,cx,cy){const fr=document.getElementById('frame').getBoundingClientRect();const fx=fr.width?(cx-fr.left)/fr.width:0.5,fy=fr.height?(cy-fr.top)/fr.height:0.5;setZ(z*factor);const nf=document.getElementById('frame').getBoundingClientRect();window.scrollBy(nf.left+fx*nf.width-cx,nf.top+fy*nf.height-cy);}
document.getElementById('zi').onclick=()=>zoomAt(1.3,innerWidth/2,innerHeight/2);
document.getElementById('zo').onclick=()=>zoomAt(1/1.3,innerWidth/2,innerHeight/2);
document.getElementById('rs').onclick=()=>setZ(100);
addEventListener('wheel',e=>{if(e.ctrlKey){e.preventDefault();zoomAt(e.deltaY<0?1.1:0.909,e.clientX,e.clientY);}},{passive:false});
addEventListener('resize',relabel);
function padTop(){const h=document.querySelector('header').offsetHeight;document.querySelector('.stage').style.paddingTop=(h+16)+'px';
 const mh=(window.innerHeight-h-28)+'px';
 const c=document.getElementById('card');if(c)c.style.maxHeight=mh;
 const p=document.getElementById('precp');if(p){p.style.maxHeight=mh;p.style.top=(h+12)+'px';}}
addEventListener('resize',padTop);addEventListener('load',()=>{padTop();relabel();});
/* ---- selector de distrito ---- */
const RINFO={R0:['#9aa7b1','muy bajo'],R1:['#f4d06a','bajo'],R2:['#f0a24a','medio'],R3:['#ec7038','alto'],R4:['#cf3b28','muy alto'],R5:['#8f1b12','extremo']};
const CHIPYRS=['1983','1987','1992','1998','2016','2017','2023','2024','2026'];
const keymap=new Map();
(OV.distritos||[]).forEach(f=>{const lab=f.name+(f.pr?' · '+f.pr:'')+(f.dp&&f.dp!==f.pr?', '+f.dp:'');let k=lab,n=2;while(keymap.has(k)){k=lab+' ('+n+')';n++;}keymap.set(k,f);f._k=k;});
const dlist=document.getElementById('distlist');
[...keymap.keys()].sort().forEach(k=>{const o=document.createElement('option');o.value=k;dlist.appendChild(o);});
function fillCard(f){document.getElementById('cName').textContent=f.name;
 document.getElementById('cSub').textContent=(f.pr||'')+(f.dp?', '+f.dp:'')+(f.ub?' · '+f.ub:'');
 const ri=RINFO[f.R]||['#9aa7b1','s/d'];
 document.getElementById('cR').innerHTML='<span class="rbadge" style="background:'+ri[0]+'">'+(f.R||'s/d')+' — '+ri[1]+'</span>';
 const comp=[['Severidad',f.sev],['Recurrencia',f.rec],['Fragilidad',f.fra],['Exposición',f.exn]];
 let sch=comp.map(c=>{const v=parseFloat(c[1]);const pct=isNaN(v)?0:Math.max(0,Math.min(1,v))*100;return '<div class="scrow"><b>'+c[0]+'</b><div class="scbar"><i style="width:'+pct.toFixed(0)+'%;background:'+ri[0]+'"></i></div><em>'+(isNaN(v)?'—':v.toFixed(2))+'</em></div>';}).join('');
 const sv=parseFloat(f.sc);const spct=isNaN(sv)?0:Math.max(0,Math.min(1,sv/4))*100;
 sch+='<div class="scrow tot"><b>Score total</b><div class="scbar"><i style="width:'+spct.toFixed(0)+'%;background:'+ri[0]+'"></i></div><em>'+(isNaN(sv)?'—':sv.toFixed(2)+'/4')+'</em></div>';
 document.getElementById('cScore').innerHTML=sch;
 const st=STATS[f.ub],compEl=document.getElementById('cComp'),compT=document.getElementById('cCompT');
 if(st&&st.p>0){const P=st.p,pc=n=>Math.round(100*n/P);const resto=P-st.ma;
  compEl.innerHTML='<div class="ccov"><b>≤300m precisas:</b> '+P.toLocaleString('es-PE')+' de '+st.t.toLocaleString('es-PE')+' ('+Math.round(100*P/st.t)+'%)</div>'+
   '<div class="cbar"><i style="width:'+pc(st.ma)+'%;background:#AE1A1A"></i><i style="width:'+pc(resto)+'%;background:#586472"></i></div>'+
   '<div class="cleg2"><span><span class="d" style="background:#AE1A1A"></span>Altamente susceptible '+pc(st.ma)+'%</span><span><span class="d" style="background:#586472"></span>Resto '+pc(resto)+'%</span></div>';
  compEl.style.display='';compT.style.display='';}
 else{compEl.style.display='none';compT.style.display='none';}
 const pac=f.pac==='1';
 const kv=[['Cuenca',f.cu||'—'],['Vertiente Pacífico',pac?'Sí (gate activo)':'No'],['% expuesto',(f.pe!==undefined&&f.pe!==''?f.pe+'%':'—')],['Nº eventos',(f.ne!==undefined&&f.ne!==''?f.ne:'—')],['Patrón',f.pat||'—']];
 document.getElementById('cKv').innerHTML=kv.map(x=>'<b>'+x[0]+'</b><span>'+x[1]+'</span>').join('');
 const hit=new Set(f.yr||[]);
 document.getElementById('cYrs').innerHTML=CHIPYRS.map(y=>'<span class="'+(hit.has(y)?'hit':'')+'">'+y+'</span>').join('');
 // impacto humano 2017
 const esc=s=>String(s||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
 const fmt=n=>(+n||0).toLocaleString('es-PE');
 const im=f.im,impEl=document.getElementById('cImp'),impT=document.getElementById('cImpT'),impN=document.getElementById('cImpNote');
 if(im){const st=[['Damnificados',im.dam],['Afectados',im.afe],['Viviendas',im.viv]];if(+im.fall>0)st.push(['Fallecidos',im.fall]);
  impEl.innerHTML=st.map(s=>'<div class="st"><b>'+fmt(s[1])+'</b><span>'+s[0]+'</span></div>').join('');
  impEl.style.display='flex';impT.style.display='';impN.style.display='';}
 else{impEl.style.display='none';impT.style.display='none';impN.style.display='none';}
 // evidencia en prensa
 const nw=f.news||[],nwEl=document.getElementById('cNews'),nwT=document.getElementById('cNewsT');
 if(nw.length){nwEl.innerHTML=nw.map(o=>{const tag=o.estado?'<span class="tag">'+esc(o.estado.replace(/_/g,' '))+'</span>':'';
   const link=o.url?'<a href="'+esc(o.url)+'" target="_blank" rel="noopener">Ver fuente ↗</a>':'';
   return '<div class="it">'+tag+'<p>'+esc(o.ev)+'</p>'+link+'</div>';}).join('');
  nwEl.style.display='flex';nwT.style.display='';}
 else{nwEl.innerHTML='';nwEl.style.display='none';nwT.style.display='none';}
 document.getElementById('card').classList.add('on');}
let curFeat=null;const _ptsCache={};
async function loadPts(ub){if(ub in _ptsCache)return _ptsCache[ub];try{const r=await fetch('ibk_pts/'+ub+'.bin');if(!r.ok){_ptsCache[ub]=null;return null;}const b=await r.arrayBuffer();const n=new DataView(b).getUint32(0,true);const o={n:n,col:new Float32Array(b,4,n),row:new Float32Array(b,4+n*4,n),tier:new Uint8Array(b,4+n*8,n)};_ptsCache[ub]=o;return o;}catch(e){_ptsCache[ub]=null;return null;}}
function hidePts(){document.getElementById('ovPts').style.display='none';}
async function drawPtsFor(f){const cv=document.getElementById('ovPts');
 const nums=(f.d.match(/-?\d+(?:\.\d+)?/g)||[]).map(Number);let mnx=1e9,mny=1e9,mxx=-1e9,mxy=-1e9;
 for(let i=0;i+1<nums.length;i+=2){const x=nums[i],y=nums[i+1];if(x<mnx)mnx=x;if(x>mxx)mxx=x;if(y<mny)mny=y;if(y>mxy)mxy=y;}
 const bw=Math.max(1,mxx-mnx),bh=Math.max(1,mxy-mny);
 cv.style.left=(mnx/OV.W*100)+'%';cv.style.top=(mny/OV.H*100)+'%';cv.style.width=(bw/OV.W*100)+'%';cv.style.height=(bh/OV.H*100)+'%';
 const cw=Math.min(3600,Math.max(1400,bw*550/3));cv.width=Math.round(cw);cv.height=Math.max(1,Math.round(cw*bh/bw));
 const ctx=cv.getContext('2d');ctx.clearRect(0,0,cv.width,cv.height);cv.style.display='block';
 const d=await loadPts(f.ub);if(!d){cv.style.display='none';return;}
 // recorte a la forma real del distrito (para no ver un cuadrado)
 const p2=new Path2D();let re=/([ML])\s*(-?\d+(?:\.\d+)?)\s+(-?\d+(?:\.\d+)?)|Z/g,mm;
 while((mm=re.exec(f.d))){if(mm[0]==='Z'){p2.closePath();continue;}const gx=+mm[2],gy=+mm[3];const px=((gx-mnx)/bw)*cv.width,py=((gy-mny)/bh)*cv.height;if(mm[1]==='M')p2.moveTo(px,py);else p2.lineTo(px,py);}
 ctx.save();ctx.clip(p2);
 const want=new Set();if(isOn('tI3'))want.add(0);if(isOn('tI5')){want.add(0);want.add(1);}if(isOn('tI1')){want.add(0);want.add(1);want.add(2);}
 if(want.size===0)want.add(0);/* default: solo <=300m; los puntos NUNCA muestran localidad (morado) */
 const COL=['#0a7d3a','#2ea86a','#63cf92','#9b59b6'];const ds=Math.max(1.6,cv.width/560);
 for(const tt of [2,1,0]){if(!want.has(tt))continue;ctx.fillStyle=COL[tt];for(let i=0;i<d.n;i++){if(d.tier[i]!==tt)continue;ctx.fillRect(((d.col[i]-mnx)/bw)*cv.width-ds/2,((d.row[i]-mny)/bh)*cv.height-ds/2,ds,ds);}}
 ctx.restore();
 ctx.lineWidth=Math.max(1.6,cv.width/360);ctx.strokeStyle='#4ade80';ctx.lineJoin='round';ctx.stroke(p2);}
function selectDist(f){const sel=document.getElementById('ovSel');sel.innerHTML='';
 const p=document.createElementNS(NS,'path');p.setAttribute('d',f.d);p.setAttribute('class','selp');sel.appendChild(p);
 const t=document.createElementNS(NS,'text');t.setAttribute('x',f.lx);t.setAttribute('y',f.ly);t.setAttribute('class','sellbl');t.textContent=f.name;sel.appendChild(t);
 const nums=(f.d.match(/-?\d+(?:\.\d+)?/g)||[]).map(Number);let mnx=1e9,mny=1e9,mxx=-1e9,mxy=-1e9;
 for(let i=0;i+1<nums.length;i+=2){const x=nums[i],y=nums[i+1];if(x<mnx)mnx=x;if(x>mxx)mxx=x;if(y<mny)mny=y;if(y>mxy)mxy=y;}
 const wpx=Math.max(6,mxx-mnx),hpx=Math.max(6,mxy-mny);
 let zz=Math.min(0.82*100*OV.W/wpx,0.82*100*OV.H/hpx);zz=Math.max(220,Math.min(16000,zz));
 setZ(zz);
 requestAnimationFrame(()=>{const fr=document.getElementById('frame').getBoundingClientRect();
  sel.style.setProperty('--sellf',(15*OV.W/fr.width)+'px');
  const px=window.scrollX+fr.left+(f.lx/OV.W)*fr.width,py=window.scrollY+fr.top+(f.ly/OV.H)*fr.height;
  window.scrollTo({left:px-innerWidth/2,top:py-innerHeight/2-30,behavior:'smooth'});});
 fillCard(f);curFeat=f;if(isOn('tPts'))drawPtsFor(f);else hidePts();}
function clearSel(){document.getElementById('ovSel').innerHTML='';document.getElementById('card').classList.remove('on');document.getElementById('find').value='';curFeat=null;hidePts();}
const find=document.getElementById('find');
function tryFind(){const v=find.value.trim();if(!v)return;let f=keymap.get(v);
 if(!f){const lo=v.toLowerCase();const e=[...keymap.entries()].find(([k])=>k.toLowerCase()===lo)||[...keymap.entries()].find(([k])=>k.toLowerCase().startsWith(lo));if(e)f=e[1];}
 if(f){find.value=f._k;selectDist(f);}}
find.addEventListener('change',tryFind);
find.addEventListener('keydown',e=>{if(e.key==='Enter')tryFind();});
document.getElementById('findx').onclick=clearSel;
document.getElementById('cardx').onclick=clearSel;
document.getElementById('cardmin').onclick=()=>{const m=document.getElementById('card').classList.toggle('min');document.getElementById('cardmin').textContent=m?'+':'–';document.getElementById('cardmin').title=m?'Expandir':'Minimizar';};
/* selector en cascada Depto -> Prov -> Distrito, filtrable por Score FEN (R0-R5) */
const byUb={};(OV.distritos||[]).forEach(f=>{byUb[f.ub]=f;});
const selR=new Set();let tree={};
function buildTree(){tree={};(OV.distritos||[]).forEach(f=>{if(selR.size&&!selR.has(f.R))return;const dp=f.dp||'—',pr=f.pr||'—';(tree[dp]=tree[dp]||{});(tree[dp][pr]=tree[dp][pr]||[]).push(f);});}
const selDep=document.getElementById('selDep'),selProv=document.getElementById('selProv'),selDist=document.getElementById('selDist');
function fillDep(){selDep.innerHTML='<option value="">Departamento…</option>';Object.keys(tree).sort().forEach(dp=>selDep.add(new Option(dp,dp)));selProv.innerHTML='<option value="">Provincia…</option>';selProv.disabled=true;selDist.innerHTML='<option value="">Distrito…</option>';selDist.disabled=true;}
buildTree();fillDep();
selDep.onchange=()=>{selProv.innerHTML='<option value="">Provincia…</option>';selDist.innerHTML='<option value="">Distrito…</option>';selDist.disabled=true;
 const dp=selDep.value;if(!dp){selProv.disabled=true;return;}selProv.disabled=false;
 Object.keys(tree[dp]).sort().forEach(pr=>selProv.add(new Option(pr,pr)));};
selProv.onchange=()=>{selDist.innerHTML='<option value="">Distrito…</option>';const dp=selDep.value,pr=selProv.value;if(!pr){selDist.disabled=true;return;}selDist.disabled=false;
 tree[dp][pr].slice().sort((a,b)=>a.name.localeCompare(b.name)).forEach(f=>selDist.add(new Option(f.name+' ('+(f.R||'')+')',f.ub)));};
selDist.onchange=()=>{const f=byUb[selDist.value];if(f)selectDist(f);};
document.querySelectorAll('.rf').forEach(b=>{const R=b.dataset.r,ri=RINFO[R]||['#888'];b.style.borderColor=ri[0];b.title=R+' — '+ri[1];
 b.onclick=()=>{const on=b.getAttribute('aria-pressed')!=='true';b.setAttribute('aria-pressed',on);b.style.background=on?ri[0]:'';b.style.color=on?'#fff':'';if(on)selR.add(R);else selR.delete(R);buildTree();fillDep();};});
build();draw();relabel();padTop();
</script></body></html>'''
out=D+'mapa_altasusc_cuencas.html'
open(out,'w',encoding='utf-8').write(HTML.replace('__OV__',OV).replace('__ST__',ST))
print('escrito',out,'|',round(os.path.getsize(out)/1024),'KB')
