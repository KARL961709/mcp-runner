'use strict';
// ============================================================================================
// DECK FEN — alto nivel para VP / CEO.  UNA IDEA POR SLIDE.
//   1 · dónde duele        → los dos mapas
//   2 · cómo entra a la PD → el reparto conserva el total
//   3 · cuándo se activa   → la rampa de información
//   4 · el índice IBK+     → la lectura correcta
// Regla de edición: título = conclusión, un visual dominante, máximo 3 cifras, sin párrafos.
// Todos los gráficos son SVG generados del dato.
// ============================================================================================
const fs = require('fs');
const B = 'C:/Users/CARLOS/elnino_ibk';
const SP = 'C:/Users/CARLOS/AppData/Local/Temp/claude/C--Users-CARLOS/07087cf8-13e1-4bbe-85fc-06afd5ab8fa2/scratchpad/';

// --- datos -----------------------------------------------------------------------------------
const geo = JSON.parse(fs.readFileSync(B + '/01_inputs/geo/peru_dist.geojson', 'utf8'));
const L = fs.readFileSync(B + '/02_pipeline/out/fen_v5.csv', 'utf8').replace(/^\uFEFF/, '').trim().split(/\r?\n/);
const H = L[0].split(','); const ix = {}; H.forEach((h, i) => ix[h] = i);
const D = new Map();
for (const l of L.slice(1)) {
  const c = l.match(/(?:^|,)("(?:[^"]|"")*"|[^,]*)/g).map(s => s.replace(/^,/, '').replace(/^"|"$/g, ''));
  D.set(c[ix.ubigeo], c);
}
const AGRO = JSON.parse(fs.readFileSync(SP + 'seq_agro.json', 'utf8'));
const hasArr = Object.values(AGRO).map(o => o.ha).filter(x => x > 0).sort((a, b) => a - b);
const capHa = hasArr[Math.floor(0.90 * hasArr.length)];
const nivAgro = u => { const o = AGRO[u]; if (!o || o.ha <= 0) return 0;
  const r = Math.min(o.ha / capHa, 1); return r >= 0.5 ? 4 : r >= 0.2 ? 3 : r >= 0.05 ? 2 : 1; };

// --- proyección del mapa ---------------------------------------------------------------------
const W = 560, PAD = 5;
let lo0 = 180, lo1 = -180, la0 = 90, la1 = -90;
const scan = g => (g.type === 'Polygon' ? g.coordinates : g.coordinates.flat()).forEach(r => r.forEach(p => {
  if (p[0] < lo0) lo0 = p[0]; if (p[0] > lo1) lo1 = p[0];
  if (p[1] < la0) la0 = p[1]; if (p[1] > la1) la1 = p[1]; }));
geo.features.forEach(f => f.geometry && scan(f.geometry));
const kx = Math.cos((la0 + la1) / 2 * Math.PI / 180);
const sx = (W - 2 * PAD) / ((lo1 - lo0) * kx);
const HH = Math.round((la1 - la0) * sx + 2 * PAD);
const px = (lo, la) => [Math.round(PAD + (lo - lo0) * kx * sx), Math.round(PAD + (la1 - la) * sx)];
const ring = r => 'M' + r.map(p => px(p[0], p[1]).join(' ')).join('L') + 'Z';
const pathOf = g => g.type === 'Polygon' ? g.coordinates.map(ring).join('')
  : g.coordinates.map(poly => poly.map(ring).join('')).join('');

const RAMP_R = ['#e2e6ea', '#ffcf4d', '#ffa32e', '#ef6f26', '#d8401f', '#a8140f'];
const RAMP_A = ['#e2e6ea', '#a9dcc0', '#5cbe8c', '#12a05e', '#00693a'];
const SIN = '#c6ccd3';

const paths = [];
for (const f of geo.features) {
  if (!f.geometry) continue;
  const row = D.get(f.properties.IDDIST);
  paths.push({ d: pathOf(f.geometry),
    rn: row ? (parseInt(String(row[ix.r_directo]).replace('R', ''), 10) || 0) : null,
    an: row ? nivAgro(row[ix.ubigeo]) : null });
}
const defs = '<svg width="0" height="0" style="position:absolute" aria-hidden="true"><defs>' +
  paths.map((p, i) => '<path id="m' + i + '" d="' + p.d + '"/>').join('') + '</defs></svg>';
const mapa = (key, ramp) => '<svg class="mp" viewBox="0 0 ' + W + ' ' + HH + '" role="img" aria-label="Mapa del Peru">' +
  '<g stroke="#fff" stroke-width="0.4" stroke-linejoin="round">' +
  paths.map((p, i) => '<use href="#m' + i + '" fill="' + (p[key] == null ? SIN : ramp[p[key]]) + '"/>').join('') +
  '</g></svg>';

const rows = [...D.values()];
const nR = [0,0,0,0,0,0]; rows.forEach(c => nR[parseInt(String(c[ix.r_directo]).replace('R',''),10)||0]++);
const haTot = Object.values(AGRO).reduce((a,o)=>a+o.ha,0);
const ganTot = Object.values(AGRO).reduce((a,o)=>a+o.gan,0);
const un = n => (Math.round(n/1e5)/10).toString().replace('.',',');

// ============ GRÁFICO · el reparto conserva el total ============
// Multiplicador que recibe cada nivel sobre el movimiento nacional. La línea punteada en 1x es
// el promedio ponderado por exposición: por construcción vale exactamente 1, o sea el total
// del banco no cambia. Se dibuja así y no por áreas porque R0 tiene 1.115 distritos y R5 sólo 54:
// con anchos proporcionales R5 quedaría invisible y el mensaje se perdería.
function gReparto(){
  const N=[['R5',3.0],['R4',2.1],['R3',1.3],['R2',0.8],['R1',0.4],['R0',0.15]];
  const cols=['#a8140f','#d8401f','#ef6f26','#ffa32e','#ffcf4d','#c6ccd3'];
  const w=900,h=310,ml=118,mr=30,mt=30,mb=58,gap=22;
  const bw=(w-ml-mr-gap*5)/6, base=h-mb, esc=(base-mt)/3.4;
  let s='<svg viewBox="0 0 '+w+' '+h+'" class="gr">';
  // barras
  N.forEach((d,i)=>{const x=ml+i*(bw+gap), bh=d[1]*esc;
    s+='<rect x="'+x+'" y="'+(base-bh)+'" width="'+bw+'" height="'+bh+'" fill="'+cols[i]+'"/>';
    s+='<text x="'+(x+bw/2)+'" y="'+(base-bh-14)+'" class="gn" text-anchor="middle" fill="'+cols[i]+'">'+d[1].toFixed(1).replace('.',',')+'×</text>';
    s+='<text x="'+(x+bw/2)+'" y="'+(base+26)+'" class="gb" text-anchor="middle" fill="#111">'+d[0]+'</text>';});
  // linea del promedio ponderado
  s+='<line x1="'+(ml-58)+'" y1="'+(base-esc)+'" x2="'+(w-mr)+'" y2="'+(base-esc)+'" stroke="#00A94F" stroke-width="3" stroke-dasharray="9 7"/>';
  s+='<text x="'+(ml-66)+'" y="'+(base-esc-10)+'" class="gk" fill="#00A94F" text-anchor="start">1×</text>';
  s+='<text x="'+(ml-66)+'" y="'+(base-esc+18)+'" class="gm" fill="#00A94F" text-anchor="start">PROMEDIO</text>';
  s+='<line x1="'+(ml-58)+'" y1="'+base+'" x2="'+(w-mr)+'" y2="'+base+'" stroke="#111" stroke-width="2"/>';
  s+='<text x="'+((ml+w-mr)/2)+'" y="'+(h-8)+'" class="gl" text-anchor="middle">EL PROMEDIO PONDERADO ES 1× — EL TOTAL DEL BANCO NO CAMBIA</text>';
  s+='</svg>';return s;
}

// ============ GRÁFICO · la rampa de información ============
function gRampa(){
  const datos=[['MAY',2],['JUN',6],['JUL',11],['AGO',18],['SET',22],['OCT',27],['NOV',33],['DIC',42],['ENE-ABR',100]];
  const w=900,h=310,ml=20,mb=52,mt=40,gap=14;
  const bw=(w-ml-20-gap*(datos.length-1))/datos.length;
  let s='<svg viewBox="0 0 '+w+' '+h+'" class="gr">';
  datos.forEach(([m,v],i)=>{
    const x=ml+i*(bw+gap), hh=(v/100)*(h-mt-mb), y=h-mb-hh;
    const hoy=m==='AGO', full=v===100;
    s+='<rect x="'+x+'" y="'+y+'" width="'+bw+'" height="'+hh+'" fill="'+(full?'#a8140f':hoy?'#00A94F':'#111')+'" opacity="'+(full||hoy?1:.2)+'"/>';
    s+='<text x="'+(x+bw/2)+'" y="'+(y-11)+'" class="gn" text-anchor="middle" fill="'+(full?'#a8140f':hoy?'#00A94F':'#8a8a8a')+'">'+v+'%</text>';
    s+='<text x="'+(x+bw/2)+'" y="'+(h-mb+22)+'" class="gm" text-anchor="middle" fill="'+(hoy?'#00A94F':full?'#a8140f':'#a5a5a5')+'">'+m+'</text>';});
  s+='<text x="'+(ml+3*(bw+gap)+bw/2)+'" y="'+(h-mb+42)+'" class="gk" fill="#00A94F" text-anchor="middle">HOY</text>';
  s+='</svg>';return s;
}

// ============ GRÁFICO · IBK+ Piura vs Nacional en Yaku ============
function gIbk(){
  const S=[['N',1.92,1.88],['D',1.44,0.97],['E-23',2.66,2.01],['F',1.12,0.33],['M',1.15,-0.11],
    ['A',1.99,0.16],['M',2.49,0.56],['J',2.20,0.33],['J',2.51,0.35],['A',2.35,0.11],
    ['S',2.21,-0.17],['O',1.53,-0.57],['N',1.24,-0.48],['D',1.41,0.32]];
  const w=900,h=300,ml=52,mr=16,mt=34,mb=44;
  const X=i=>ml+i*((w-ml-mr)/(S.length-1)), Y=v=>h-mb-((v+1)/4)*(h-mt-mb);
  let s='<svg viewBox="0 0 '+w+' '+h+'" class="gr">';
  s+='<rect x="'+X(4)+'" y="'+mt+'" width="'+(X(7)-X(4))+'" height="'+(h-mt-mb)+'" fill="#a8140f" opacity=".08"/>';
  s+='<text x="'+((X(4)+X(7))/2)+'" y="'+(mt-9)+'" class="gk" fill="#a8140f" text-anchor="middle">YAKU · MARZO 2023</text>';
  [-1,0,1,2,3].forEach(v=>{s+='<line x1="'+ml+'" y1="'+Y(v)+'" x2="'+(w-mr)+'" y2="'+Y(v)+'" stroke="'+(v===0?'#111':'#eee')+'"/>';
    s+='<text x="'+(ml-9)+'" y="'+(Y(v)+5)+'" class="gm" text-anchor="end" fill="#a5a5a5">'+(v>0?'+':'')+v+'%</text>';});
  s+='<line x1="'+ml+'" y1="'+Y(2.71)+'" x2="'+(w-mr)+'" y2="'+Y(2.71)+'" stroke="#00A94F" stroke-width="2.5" stroke-dasharray="7 6"/>';
  s+='<text x="'+(w-mr)+'" y="'+(Y(2.71)-11)+'" class="gk" fill="#00A94F" text-anchor="end">SU PROPIA TENDENCIA · +2,71%</text>';
  s+='<polyline points="'+S.map((d,i)=>X(i)+','+Y(d[2])).join(' ')+'" fill="none" stroke="#bdbdbd" stroke-width="3.5"/>';
  s+='<polyline points="'+S.map((d,i)=>X(i)+','+Y(d[1])).join(' ')+'" fill="none" stroke="#111" stroke-width="4"/>';
  S.forEach((d,i)=>{s+='<circle cx="'+X(i)+'" cy="'+Y(d[1])+'" r="4" fill="#111"/>';
    s+='<text x="'+X(i)+'" y="'+(h-mb+21)+'" class="gm" text-anchor="middle" fill="#a5a5a5">'+d[0]+'</text>';});
  s+='<text x="'+(X(0)+10)+'" y="'+(Y(1.92)-13)+'" class="gk" fill="#111">PIURA</text>';
  s+='<text x="'+(X(0)+10)+'" y="'+(Y(1.88)+22)+'" class="gk" fill="#a5a5a5">NACIONAL</text>';
  s+='</svg>';return s;
}

// ============ GRAFICO · CRONOGRAMA ============
// Dias habiles L-V. Feriado del periodo: Santa Rosa de Lima, 30 de agosto, que en 2026 cae DOMINGO
// y por lo tanto no descuenta ningun habil. Cada frente son 10 habiles = 2 semanas.
const CRON = JSON.parse(fs.readFileSync(B + '/03_deck/_cron.json', 'utf8'));
function gCron(){
  const cal = CRON.cal, N = cal.length;
  const w = 1020, h = 228, ml = 272, mr = 22, mt = 74, fila = 30;
  const cw = (w - ml - mr) / N;
  const ix = f => cal.findIndex(c => c[0] === f);
  let s = '<svg viewBox="0 0 '+w+' '+h+'" class="gr">';
  // fondo: sabados y domingos sombreados, para que se vea que no se cuentan
  cal.forEach((c, i) => {
    if (!c[2]) s += '<rect x="'+(ml+i*cw).toFixed(1)+'" y="'+(mt-28)+'" width="'+cw.toFixed(1)+'" height="'+(h-mt-6)+'" fill="'+(c[3]?'#f6e3e2':'#f0f1f2')+'"/>';
  });
  // eje de dias
  cal.forEach((c, i) => {
    const x = ml + i*cw + cw/2, dia = +c[0].slice(8);
    s += '<text x="'+x.toFixed(1)+'" y="'+(mt-34)+'" class="gm" text-anchor="middle" fill="'+(c[2]?'#111':'#c3c3c3')+'">'+dia+'</text>';
    s += '<text x="'+x.toFixed(1)+'" y="'+(mt-46)+'" class="gm" text-anchor="middle" fill="'+(c[2]?'#a5a5a5':'#d5d5d5')+'">'+c[1][0].toUpperCase()+'</text>';
    if (c[3] && c[1]!=='sab' && c[1]!=='dom') s += '<text x="'+x.toFixed(1)+'" y="'+(mt-58)+'" class="gm" text-anchor="middle" fill="#a8140f">FER</text>';
  });
  // hoy
  const hx = ml + ix('2026-08-03')*cw;
  s += '<line x1="'+hx.toFixed(1)+'" y1="'+(mt-28)+'" x2="'+hx.toFixed(1)+'" y2="'+(h-6)+'" stroke="#00A94F" stroke-width="2.5"/>';
  s += '<text x="'+(hx+6).toFixed(1)+'" y="'+(h-10)+'" class="gk" fill="#00A94F">HOY</text>';
  // arranques
  [['2026-08-10','ARRANQUE 1'],['2026-08-12','ARRANQUE 2']].forEach(([f,t]) => {
    const x = ml + ix(f)*cw;
    s += '<line x1="'+x.toFixed(1)+'" y1="'+(mt-28)+'" x2="'+x.toFixed(1)+'" y2="'+(h-26)+'" stroke="#111" stroke-width="1.2" stroke-dasharray="3 4"/>';
  });
  // barras
  CRON.tareas.forEach((t, k) => {
    const [nm, ini, fin] = t;
    const a = ix(ini), b = ix(fin);
    const y = mt + k*fila, bh = 18;
    const x0 = ml + a*cw, x1 = ml + (b+1)*cw;
    s += '<text x="'+(ml-14)+'" y="'+(y+16)+'" class="gk" text-anchor="end" fill="#111">'+nm+'</text>';
    const est = t[3]===2;
    s += '<rect x="'+x0.toFixed(1)+'" y="'+y+'" width="'+(x1-x0).toFixed(1)+'" height="'+bh+'" fill="'+(est?'#fff':(t[3]?'#00A94F':'#111'))+'" stroke="'+(est?'#00A94F':'none')+'" stroke-width="2" stroke-dasharray="'+(est?'5 4':'0')+'"/>';
    const nh = t[3]===1?'4':t[3]===2?'5':'10';
    s += '<text x="'+(x0+7).toFixed(1)+'" y="'+(y+15)+'" class="gm" fill="'+(est?'#00A94F':'#fff')+'">'+nh+' días hábiles</text>';
    s += '<text x="'+(x1+8).toFixed(1)+'" y="'+(y+15)+'" class="gk" fill="'+(t[3]?'#00A94F':'#111')+'">'+(+fin.slice(8))+' ago'+(est?' est.':'')+'</text>';
  });
  return s + '</svg>';
}
// --- estilos ---------------------------------------------------------------------------------
const css = `
html,body{width:100%;height:100%;margin:0;overflow:hidden;background:var(--stage-bg,#000)}
.deck-viewport{position:fixed;inset:0;overflow:hidden;background:var(--stage-bg,#000)}
.deck-stage{position:absolute;left:0;top:0;width:1920px;height:1080px;overflow:hidden;
transform-origin:0 0;background:var(--slide-bg,#fff)}
.slide{position:absolute;inset:0;width:1920px;height:1080px;overflow:hidden;display:block;
visibility:hidden;opacity:0;pointer-events:none;background:var(--slide-bg,#fff)}
.slide.active,.slide.visible{visibility:visible;opacity:1;pointer-events:auto;z-index:1}
img,video,canvas{max-width:100%;max-height:100%}
.deck-controls{position:fixed;left:50%;bottom:22px;transform:translateX(-50%);z-index:1000}
@media print{html,body{width:1920px;height:auto;overflow:visible;background:#fff}
.deck-viewport{position:static;overflow:visible;background:#fff}
.deck-stage{position:static;width:auto;height:auto;transform:none!important;background:none}
.slide{position:relative;display:block!important;visibility:visible!important;opacity:1!important;
pointer-events:auto!important;width:1920px;height:1080px;break-after:page;page-break-after:always}
.slide:last-child{break-after:auto;page-break-after:auto}
.deck-controls{display:none!important}}
@media (prefers-reduced-motion:reduce){*,*::before,*::after{animation-duration:.01ms!important;
transition-duration:.2s!important}}

:root{--stage-bg:#111;--slide-bg:#fff;--ink:#000;--green:#00A94F;--gray:#6e6e6e;--soft:#d8d8d8;--rain:#a8140f}
@keyframes rise{to{opacity:1;transform:none}}
@keyframes grow{from{transform:scaleX(0)}to{transform:scaleX(1)}}
@keyframes drop{from{transform:scaleY(0)}to{transform:scaleY(1)}}
.deck-controls{display:flex;align-items:center;gap:14px;background:rgba(0,0,0,.72);
border-radius:100px;padding:9px 16px;backdrop-filter:blur(6px)}
.deck-controls button{all:unset;cursor:pointer;color:#fff;font:600 13px/1 'Nunito',sans-serif;
padding:5px 9px;border-radius:100px;opacity:.85}
.deck-controls button:hover{opacity:1;background:rgba(255,255,255,.14)}
.deck-controls .cnt{color:#fff;font:700 12px/1 'Archivo',sans-serif;letter-spacing:2px;opacity:.9;min-width:44px;text-align:center}
.dots{display:flex;gap:7px}
.dots i{width:8px;height:8px;border-radius:50%;background:rgba(255,255,255,.35);cursor:pointer;display:block}
.dots i.on{background:#00A94F}

.slide{font-family:'Nunito',sans-serif;color:var(--ink)}
.mark{position:absolute;right:0;top:0;width:26px;height:432px;background:var(--green)}
.mark::after{content:"";position:absolute;left:-26px;top:432px;width:26px;height:132px;background:var(--ink)}
.pad{position:absolute;inset:0;padding:74px 100px 60px;display:flex;flex-direction:column}
.kick{display:flex;align-items:center;gap:18px;font-family:'Archivo';font-weight:600;font-size:16px;
letter-spacing:4.4px;text-transform:uppercase;color:var(--gray)}
.kick .sq{width:16px;height:16px;background:var(--green);flex:none}
h1{font-family:'Archivo';font-weight:900;font-size:82px;line-height:.98;letter-spacing:-3.2px;margin:22px 0 0}
h1 em{font-style:normal;color:var(--green)}
h1 em.r{color:var(--rain)}
.rule{height:9px;background:var(--ink);margin-top:30px;width:100%}
.rule i{display:block;height:9px;width:236px;background:var(--green)}
.cierre{margin-top:auto;border-top:1px solid var(--soft);padding-top:22px;
font-family:'Archivo';font-weight:800;font-size:27px;letter-spacing:-.6px;line-height:1.3}
.cierre em{font-style:normal;color:var(--green)}
.cierre em.r{color:var(--rain)}
.cierre span{display:block;font-family:'Nunito';font-weight:600;font-size:19px;color:var(--gray);
margin-top:9px;letter-spacing:0;line-height:1.4}
.rv{opacity:0;transform:translateY(26px);animation:rise .78s cubic-bezier(.16,1,.3,1) forwards}
.d1{animation-delay:.05s}.d2{animation-delay:.2s}.d3{animation-delay:.36s}.d4{animation-delay:.5s}
.rule i{transform-origin:0 50%;animation:grow .9s cubic-bezier(.16,1,.3,1) .3s both}
.mark{transform-origin:50% 0;animation:drop 1s cubic-bezier(.16,1,.3,1) .15s both}

/* gráficos */
.gr{display:block;width:auto;max-width:100%;height:auto}
.gl{font-family:'Archivo';font-weight:600;font-size:13px;letter-spacing:2.6px;fill:#a5a5a5}
.gw{font-family:'Archivo';font-weight:800;font-size:19px;fill:#fff;letter-spacing:1.4px}
.gb{font-family:'Archivo';font-weight:800;font-size:16px;letter-spacing:.6px}
.gn{font-family:'Archivo';font-weight:900;font-size:22px;letter-spacing:-.6px}
.gv{font-family:'Archivo';font-weight:800;font-size:15px}
.gm{font-family:'Archivo';font-weight:600;font-size:14px;letter-spacing:1.4px}
.gk{font-family:'Archivo';font-weight:800;font-size:14px;letter-spacing:1.4px}

/* S1 · los dos mapas */
.s1 .two{display:grid;grid-template-columns:1fr 1fr;gap:0;margin-top:34px;flex:1;min-height:0}
.s1 .ax{display:grid;grid-template-columns:auto 1fr;gap:40px;align-items:center;
padding-right:56px;margin-right:56px;border-right:1px solid var(--soft)}
.s1 .ax:last-child{border-right:none;margin-right:0;padding-right:0}
.s1 .mp{height:520px;width:auto;max-width:none;max-height:none}
.s1 .hd{font-family:'Archivo';font-weight:900;font-size:40px;letter-spacing:-1.3px;line-height:1.05}
.s1 .hd.r{color:var(--rain)} .s1 .hd.g{color:var(--green)}
.s1 .hd u{text-decoration:none;display:block;font-family:'Nunito';font-weight:600;font-size:19px;
letter-spacing:2.2px;text-transform:uppercase;color:var(--gray);margin-top:12px}
.s1 .q{font-size:25px;line-height:1.4;color:var(--ink);font-weight:600;margin-top:22px}
.s1 .q b{font-weight:800}
.s1 .big{margin-top:30px}
.s1 .big b{display:block;font-family:'Archivo';font-weight:900;font-size:64px;letter-spacing:-2.6px;line-height:1}
.s1 .big b.r{color:var(--rain)} .s1 .big b.g{color:var(--green)}
.s1 .big span{display:block;font-size:19px;color:var(--gray);font-weight:600;margin-top:8px;line-height:1.3}

/* S2-S4 · un gráfico dominante */
.solo{flex:1;display:flex;flex-direction:column;justify-content:center;align-items:center;min-height:0;margin-top:12px}
.solo .gr{height:330px}
.kpis{display:flex;justify-content:center;gap:0;margin-top:26px}
.kpis div{padding:0 52px;border-right:1px solid var(--soft);text-align:center}
.kpis div:last-child{border-right:none}
.kpis b{display:block;font-family:'Archivo';font-weight:900;font-size:50px;letter-spacing:-2px;line-height:1}
.kpis b.g{color:var(--green)} .kpis b.r{color:var(--rain)}
.kpis span{display:block;font-size:18px;color:var(--gray);font-weight:600;margin-top:9px;line-height:1.3}
.eq{font-family:'JetBrains Mono',monospace;font-size:25px;font-weight:700;letter-spacing:-.5px;
background:var(--ink);color:#fff;padding:20px 34px;margin-top:8px;text-align:center}
.eq u{text-decoration:none;color:var(--green)}
.eq s{text-decoration:none;color:#ff9c8e}

/* slide de formulación — notación y = f(x), sin símbolos griegos */
.sF .fbody{display:flex;flex-direction:column;justify-content:space-between;gap:14px;margin-top:24px;flex:1;min-height:0}
.sF .fn{display:grid;grid-template-columns:52px 1fr;gap:20px;align-items:baseline;
padding-bottom:18px;border-bottom:1px solid var(--soft)}
.sF .fnum{font-family:'Archivo';font-weight:900;font-size:30px;color:var(--green);line-height:1}
.sF .feq{font-family:'Archivo';font-weight:600;font-size:28px;letter-spacing:-.6px;
color:var(--gray);line-height:1.28}
.sF .feq b{color:var(--ink);font-weight:900}
.sF .feq i{font-style:normal;color:var(--green);font-weight:800}
.sF .fi{grid-column:2;font-family:'Nunito';font-weight:600;font-size:17px;color:#9a9a9a;
margin-top:7px;line-height:1.35}
.sF .fout{background:var(--ink);color:#fff;padding:28px 34px;margin-top:4px}
.sF .feqbig{font-family:'Archivo';font-weight:600;font-size:32px;letter-spacing:-.8px;
color:#9a9a9a;line-height:1.3}
.sF .feqbig b{color:#fff;font-weight:900}
.sF .feqbig i{font-style:normal;color:var(--green);font-weight:800}
.sF .feqbig u{text-decoration:none;color:#fff;font-weight:800}
.sF .foutn{font-family:'Nunito';font-weight:600;font-size:17.5px;color:#9a9a9a;
margin-top:16px;padding-top:15px;border-top:1px solid #333;line-height:1.42}
.sF .foutn b,.sF .foutn u{color:#fff;font-weight:700;text-decoration:none}


/* ============ S1 · los cinco pasos ============ */
.sP .pasos{display:flex;flex-direction:column;justify-content:space-between;gap:8px;margin-top:22px;flex:1;min-height:0}
.sP .ps{display:grid;grid-template-columns:46px 1fr;gap:18px;align-items:baseline;
padding-bottom:13px;border-bottom:1px solid var(--soft)}
.sP .pn{font-family:'Archivo';font-weight:900;font-size:27px;color:var(--green);line-height:1}
.sP .pq{font-family:'Archivo';font-weight:600;font-size:25px;letter-spacing:-.5px;color:var(--gray);line-height:1.25}
.sP .pq b{color:var(--ink);font-weight:900}
.sP .pq i{font-style:normal;color:var(--green);font-weight:800}
.sP .pd2{grid-column:2;font-size:16.5px;color:#9a9a9a;font-weight:600;margin-top:5px;line-height:1.3}
.sP .pf{grid-column:2;font-family:'JetBrains Mono',monospace;font-size:13.5px;color:var(--green);
margin-top:5px;line-height:1.35}
.sP .pout{background:var(--ink);color:#fff;padding:22px 30px;margin-top:14px}
.sP .peq{font-family:'Archivo';font-weight:600;font-size:27px;letter-spacing:-.6px;color:#9a9a9a;line-height:1.28}
.sP .peq b{color:#fff;font-weight:900}
.sP .peq i{font-style:normal;color:var(--green);font-weight:800}
.sP .peq u{text-decoration:none;color:#fff;font-weight:800}
.sP .pn2{font-family:'Nunito';font-weight:600;font-size:16.5px;color:#9a9a9a;margin-top:12px;
padding-top:11px;border-top:1px solid #333;line-height:1.4}
.sP .pn2 b,.sP .pn2 u{color:#fff;font-weight:700;text-decoration:none}

/* ============ S2 y S3 · desglose de cada mapa ============ */
.sM .mbody{display:grid;grid-template-columns:auto 1fr;gap:52px;margin-top:24px;flex:1;min-height:0;align-items:center}
.sM .mp{height:498px;width:auto;max-width:none;max-height:none}
.sM .mcol{display:flex;flex-direction:column}
.sM .mfx{font-family:'Archivo';font-weight:600;font-size:24px;letter-spacing:-.5px;color:var(--gray);
line-height:1.3;padding-bottom:16px;border-bottom:3px solid var(--ink);margin-bottom:4px}
.sM .mfx b{color:var(--ink);font-weight:900}
.sM .mt{width:100%;border-collapse:collapse}
.sM .mt th{font-family:'Archivo';font-weight:600;font-size:12.5px;letter-spacing:1.7px;text-transform:uppercase;
color:#a5a5a5;text-align:left;padding:12px 0 8px 16px}
.sM .mt th:first-child{padding-left:0}
.sM .mt td{padding:10px 0 10px 16px;border-bottom:1px solid var(--soft);font-size:16.5px;
color:var(--gray);line-height:1.3;vertical-align:top}
.sM .mt td:first-child{padding-left:0;font-family:'Archivo';font-weight:800;font-size:16.5px;
color:var(--ink);width:23%}
.sM .mt td:last-child{font-family:'JetBrains Mono',monospace;font-size:13.5px;color:var(--green);width:34%}
.sM .mt td b{color:var(--ink);font-weight:700}
.sM .mk{display:flex;gap:0;margin-top:22px;padding-top:18px;border-top:3px solid var(--ink)}
.sM .mk div{padding-right:36px;margin-right:36px;border-right:1px solid var(--soft)}
.sM .mk div:last-child{border-right:none;margin-right:0;padding-right:0}
.sM .mk b{display:block;font-family:'Archivo';font-weight:900;font-size:40px;letter-spacing:-1.6px;line-height:1}
.sM .mk b.r{color:var(--rain)} .sM .mk b.g{color:var(--green)}
.sM .mk span{display:block;font-size:15.5px;color:var(--gray);font-weight:600;margin-top:7px;line-height:1.3}

/* ============ S4 · ubicación ============ */
.sU .ubody{display:grid;grid-template-columns:1fr 1.22fr;gap:0;margin-top:26px;flex:1;min-height:0}
.sU .ucol{padding-right:52px;margin-right:52px;border-right:1px solid var(--soft);display:flex;flex-direction:column}
.sU .ucol:last-child{border-right:none;margin-right:0;padding-right:0}
.sU .uh{font-family:'Archivo';font-weight:900;font-size:31px;letter-spacing:-1px;margin-bottom:14px}
.sU .ufx{font-family:'Archivo';font-weight:600;font-size:22px;letter-spacing:-.4px;color:var(--gray);
background:#f4f4f4;padding:14px 17px;line-height:1.3}
.sU .ufx b{color:var(--ink);font-weight:900}
.sU .ub{font-size:19px;color:var(--gray);line-height:1.4;margin-top:16px}
.sU .ub b{color:var(--ink);font-weight:800;font-family:'Archivo';font-size:22px}
.sU .ul{font-size:18px;color:var(--gray);line-height:1.4;margin-top:14px}
.sU .ul b{color:var(--ink);font-weight:700}
.sU .ualerta{margin-top:auto;background:var(--rain);color:#fff;padding:16px 19px;
font-size:17px;font-weight:600;line-height:1.4}
.sU .ualerta b{font-weight:800}
.sU .upaso{margin-top:18px;border-left:6px solid var(--green);padding:3px 0 3px 17px;
font-family:'Archivo';font-weight:800;font-size:19px;letter-spacing:-.3px}
.sU .ufx2{display:block;font-family:'JetBrains Mono',monospace;font-weight:700;font-size:15px;
color:var(--green);margin-top:7px;line-height:1.4;letter-spacing:-.2px}
.sU .ud{display:block;font-family:'Nunito';font-weight:600;font-size:16.5px;color:var(--gray);
margin-top:8px;line-height:1.38}
.sU .ud b{color:var(--ink);font-weight:800}

/* ============ S5 · ejemplo ============ */
.sE .ebody{margin-top:26px;flex:1;min-height:0;display:flex;flex-direction:column;justify-content:center}
.sE .et{width:100%;border-collapse:collapse}
.sE .et th{font-family:'Archivo';font-weight:600;font-size:13px;letter-spacing:1.5px;text-transform:uppercase;
color:#a5a5a5;text-align:right;padding:0 0 12px 18px;line-height:1.3;vertical-align:bottom}
.sE .et th:first-child{text-align:left;padding-left:0}
.sE .et th.hi{color:var(--green)} .sE .et th.hi2{color:var(--rain)}
.sE .et td{padding:16px 0 16px 18px;border-bottom:1px solid var(--soft);text-align:right;
font-family:'Archivo';font-weight:800;font-size:23px;letter-spacing:-.6px;font-variant-numeric:tabular-nums;color:var(--gray)}
.sE .et td:first-child{text-align:left;padding-left:0;font-family:'Nunito';font-weight:600;
font-size:20px;color:var(--gray);letter-spacing:0}
.sE .et td:first-child b{font-family:'Archivo';font-weight:900;font-size:22px;color:var(--ink);letter-spacing:-.5px}
.sE .et td.hi{color:var(--green);font-size:26px}
.sE .et td.hi2{color:var(--rain);font-size:28px}
.sE .et tr:last-child td{border-bottom:none}
.sE .elee{display:grid;grid-template-columns:1fr 1fr 1fr;gap:0;margin-top:26px;padding-top:20px;
border-top:3px solid var(--ink)}
.sE .elee div{padding-right:38px;margin-right:38px;border-right:1px solid var(--soft);
font-size:17.5px;color:var(--gray);line-height:1.4}
.sE .elee div:last-child{border-right:none;margin-right:0;padding-right:0}
.sE .elee b{color:var(--ink);font-weight:800}

/* ============ S6 · ejemplo geográfico SJL ============ */
.sJ .jbody{display:grid;grid-template-columns:auto 1fr;gap:56px;margin-top:24px;flex:1;min-height:0;align-items:center}
.sJ .ejbody{display:grid;grid-template-columns:1fr 1fr 1.12fr;gap:0;margin-top:20px;flex:1;min-height:0}
.sJ .ejp{padding-right:32px;margin-right:32px;border-right:1px solid var(--soft);display:flex;flex-direction:column}
.sJ .ejcol{display:flex;flex-direction:column}
.sJ .ejh{font-family:'Archivo';font-weight:900;font-size:23px;letter-spacing:-.7px;line-height:1.05}
.sJ .ejh u{text-decoration:none;display:block;font-family:'Nunito';font-weight:600;font-size:13px;
letter-spacing:1.8px;text-transform:uppercase;color:var(--gray);margin-top:5px}
.sJ .ejmap{margin-top:10px}
.sJ .ejmap svg.gr{height:300px!important;width:auto;max-width:100%;display:block;margin:0 auto}
.sJ .ejleg{display:flex;flex-wrap:wrap;gap:4px 14px;margin-top:10px}
.sJ .ejleg span{display:flex;align-items:center;gap:6px;font-family:'Archivo';font-weight:700;font-size:12px;color:var(--gray)}
.sJ .ejleg i{width:11px;height:11px;border-radius:50%;display:block;flex:none}
.sJ .ejleg i.cu{border-radius:0;border:1.6px dashed #1b6ec2;background:rgba(27,110,194,.13);width:15px;height:11px}
.gh{paint-order:stroke;stroke:#fff;stroke-width:3.4px;stroke-linejoin:round}
.sJ .ejleg i.ln{border-radius:0;width:16px;height:0;border-top:2.6px solid #0b4d8f;background:none}
.sJ .ejleg i.ra{border-radius:50%;width:13px;height:13px;border:1.6px dashed #111;background:none}
.sJ .ejleg.pie{margin-top:14px;gap:6px 26px;justify-content:flex-start}
.sJ .ejbody.two{grid-template-columns:1.02fr 1fr}
.sJ .ejbody.tres{grid-template-columns:1fr 1fr 1.22fr}
.sR .rbody{display:grid;grid-template-columns:1.12fr 1fr;gap:0;margin-top:22px;flex:1;min-height:0}
.sR .rgraf{padding-right:34px;margin-right:34px;border-right:1px solid var(--soft);display:flex;align-items:center}
.sR .rgraf svg.gr{width:100%;height:auto;display:block}
.sR .rcol{display:flex;flex-direction:column;height:100%}
.sR .rfx{font-family:'JetBrains Mono';font-size:15px;background:#f4f5f6;border-left:3px solid var(--ink);padding:10px 13px;line-height:1.35}
.sR .rq{margin-top:13px;font-size:17px;line-height:1.4;color:var(--gray)}
.sR .rq b{color:var(--ink);font-weight:800}
.sR .rt{font-family:'Archivo';font-weight:600;font-size:12.5px;letter-spacing:2.2px;text-transform:uppercase;color:var(--gray);padding-bottom:8px;border-bottom:3px solid var(--ink);margin:22px 0 3px}
.sR .rtb{width:100%;border-collapse:collapse;margin-top:10px}
.sR .rtb td{padding:9px 0;border-bottom:1px solid var(--soft);font-size:16px;color:var(--gray)}
.sR .rtb td:nth-child(2){text-align:right;font-family:'Archivo';font-weight:800;font-size:18px;color:var(--ink);width:26%}
.sR .rtb td:last-child{text-align:right;font-size:13.5px;width:26%}
.sR .rtb td.mal{color:#a8140f;font-weight:700}
.sR .rtb td.ok{color:var(--green);font-weight:700}
.sR .rtb tr:last-child td{border-bottom:none}
.sR .ral{margin-top:18px;background:var(--ink);color:#fff;padding:15px 18px;font-size:16px;line-height:1.42}
.sR .ral b{font-weight:800}
.sR .rq2{margin-top:auto;padding-top:14px;font-size:15.5px;line-height:1.4;color:#9a9a9a}
.sR .rq2 b{color:var(--ink);font-weight:700}
.sT .tgraf{margin-top:16px}
.sT .tgraf svg.gr{width:100%;height:auto;display:block}
.sT .tbody{display:grid;grid-template-columns:1.3fr 1fr;gap:0;margin-top:18px}
.sT .ttb{width:100%;border-collapse:collapse;align-self:start;padding-right:34px;margin-right:34px;border-right:1px solid var(--soft)}
.sT .ttb th{font-family:'Archivo';font-weight:600;font-size:11.5px;letter-spacing:1.6px;text-transform:uppercase;color:var(--gray);text-align:left;padding-bottom:9px;border-bottom:2px solid var(--ink)}
.sT .ttb td{padding:5px 12px 5px 0;border-bottom:1px solid var(--soft);font-size:15.5px;color:var(--gray)}
.sT .ttb td:first-child{color:var(--ink)}
.sT .ttb td:nth-child(2),.sT .ttb td:nth-child(3){font-family:'Archivo';font-weight:700;font-size:15.5px;color:var(--ink);white-space:nowrap}
.sT .ttb td:nth-child(4){font-family:'Archivo';font-weight:800;font-size:17px;color:var(--ink);text-align:center}
.sT .ttb td:last-child{font-size:13.5px;color:#a5a5a5}
.sT .ttb tr.tard td:nth-child(3){color:var(--ink)}
.sT .ttb tr.gate td{border-bottom:2px solid var(--ink)}
.sT .ttb tr.gate td:first-child,.sT .ttb tr.gate td:nth-child(3){color:var(--green)}
.sT .ttb tr.gate td:nth-child(4){color:var(--green)}
.sT .ttb tr.est td:first-child,.sT .ttb tr.est td:nth-child(3),.sT .ttb tr.est td:nth-child(4){color:var(--green)}
.sT .ttb tr.est td i{font-style:normal;font-family:'Nunito';font-weight:600;font-size:12px;color:#9fcfb2}
.sT .btb{width:100%;border-collapse:collapse;margin-bottom:18px}
.sT .btb td{padding:9px 0;border-bottom:1px solid var(--soft);font-size:15.5px;color:var(--ink)}
.sT .btb td span{display:block;font-family:'Nunito';font-weight:400;font-size:13px;color:#a5a5a5;margin-top:2px}
.sT .btb td.tbd{text-align:right;font-family:'Archivo';font-weight:800;font-size:15px;letter-spacing:1.6px;color:#a5a5a5;width:22%;vertical-align:middle}
.sT .btb tr:last-child td{border-bottom:none}
.sT .tcol .tal{margin-top:auto}
.sT .ttb tr:last-child td{border-bottom:none}
.sT .tcol{display:flex;flex-direction:column}
.sT .tt{font-family:'Archivo';font-weight:600;font-size:12.5px;letter-spacing:2.2px;text-transform:uppercase;color:var(--gray);padding-bottom:8px;border-bottom:3px solid var(--ink);margin-bottom:14px}
.sT .tal{background:var(--ink);color:#fff;padding:14px 17px;font-size:15.5px;line-height:1.42}
.sT .tal b{font-weight:800}
.sT .tq{margin-top:11px;font-size:14.5px;line-height:1.42;color:var(--gray)}
.sT .tq b{color:var(--ink);font-weight:800}
.sJ .ejbody.tres .ejp:nth-child(2){padding-right:20px;margin-right:20px}
.sJ .ejbody.tres .ejmap{flex:1;min-height:0;display:flex;align-items:center;justify-content:center;margin-top:12px}
.sJ .ejbody.tres .ejmap svg.gr{height:520px!important;max-height:none;width:auto;max-width:100%}
.sJ .ejtb.dos th{font-family:'Archivo';font-weight:600;font-size:11.5px;letter-spacing:1.4px;text-transform:uppercase;color:var(--gray);text-align:right;padding-bottom:7px;border-bottom:1px solid var(--soft)}
.sJ .ejtb.dos th:first-child{text-align:left}
.sJ .ejtb.dos td:nth-child(2),.sJ .ejtb.dos td:nth-child(3){text-align:right;font-family:'Archivo';font-weight:800;font-size:17px;color:var(--ink);width:23%;font-variant-numeric:tabular-nums}
.sJ .ejtb.dos tr:last-child td{font-family:'Nunito';font-weight:600;font-size:13.5px;color:#a5a5a5}
.sJ .ejtb.dos tr:first-child td{color:var(--gray);font-weight:400}
.sJ .ejbody.two .ejmap{flex:1;min-height:0;display:flex;align-items:center;justify-content:center;margin-top:12px}
.sJ .ejbody.two .ejmap.alto svg.gr{height:534px!important;max-height:none;width:auto}
.sJ .ejbody.two .ejmap.cuad svg.gr{height:468px!important;max-height:none;width:auto}
.sJ .ejfx{font-family:'JetBrains Mono';font-size:15px;background:#f4f5f6;border-left:3px solid var(--ink);
padding:10px 13px;margin:0 0 13px;line-height:1.35}
.sJ .ejt2{font-family:'Archivo';font-weight:600;font-size:12.5px;letter-spacing:2.2px;text-transform:uppercase;
color:var(--gray);padding-bottom:8px;border-bottom:3px solid var(--ink);margin:20px 0 3px}
.sJ .ejleg b{color:var(--ink)}
.sJ .ejn{margin-top:auto;padding-top:12px;font-size:15.5px;line-height:1.38;color:var(--gray)}
.sJ .ejn b{color:var(--ink);font-weight:800}
.sJ .ejt{font-family:'Archivo';font-weight:600;font-size:12.5px;letter-spacing:2.2px;text-transform:uppercase;
color:var(--gray);padding-bottom:8px;border-bottom:3px solid var(--ink);margin-bottom:13px}
.sJ .ejq{font-size:18px;line-height:1.4;color:var(--gray)}
.sJ .ejq b{color:var(--ink);font-weight:800}
.sJ .ejtb{width:100%;border-collapse:collapse;margin-top:14px}
.sJ .ejtb td{padding:8px 0;border-bottom:1px solid var(--soft);font-size:15.5px;color:var(--gray)}
.sJ .ejtb td:nth-child(2){text-align:right;font-family:'Archivo';font-weight:800;font-size:18px;color:var(--ink);width:16%}
.sJ .ejtb td:last-child{text-align:right;font-size:13.5px;color:#a5a5a5;width:28%}
.sJ .ejtb.wide td:nth-child(2){font-size:17px;width:22%}
.sJ .ejtb.wide td:last-child{width:30%;font-size:14px}
.sJ .ejtb tr:first-child td{color:var(--ink);font-weight:700}
.sJ .ejtb tr:last-child td{border-bottom:none}
.sJ .ejal{margin-top:14px;background:var(--ink);color:#fff;padding:14px 17px;font-size:15.5px;line-height:1.4}
.sJ .ejal b{font-weight:800}
.sJ .ejq2{margin-top:auto;padding-top:12px;font-size:15px;line-height:1.4;color:#9a9a9a}
.sJ .ejq2 b{color:var(--ink);font-weight:700}
.sJ .jcol{display:flex;flex-direction:column}
.sJ .jq{font-size:21px;line-height:1.4;color:var(--gray);padding-bottom:18px;border-bottom:3px solid var(--ink)}
.sJ .jq b{color:var(--ink);font-weight:800}
.sJ .jt{width:100%;border-collapse:collapse;margin-top:6px}
.sJ .jt th{font-family:'Archivo';font-weight:600;font-size:12.5px;letter-spacing:1.7px;text-transform:uppercase;
color:#a5a5a5;text-align:left;padding:12px 0 8px 16px}
.sJ .jt th:first-child{padding-left:0}
.sJ .jt th:last-child{text-align:right}
.sJ .jt td{padding:11px 0 11px 16px;border-bottom:1px solid var(--soft);font-size:17.5px;color:var(--gray)}
.sJ .jt td:first-child{padding-left:0}
.sJ .jt td:last-child{text-align:right;font-family:'Archivo';font-weight:800;font-size:19px;color:var(--ink)}
.sJ .jt td b{color:var(--ink);font-weight:900;font-family:'Archivo'}
.sJ .jt tr:last-child td{border-bottom:none}
.sJ .jhall{margin-top:18px;background:var(--ink);color:#fff;padding:17px 20px;font-size:18px;line-height:1.4}
.sJ .jhall b{font-weight:800}
.sJ .jq2{font-size:17.5px;line-height:1.4;color:var(--gray);margin-top:16px}
.sJ .jq2 b{color:var(--ink);font-weight:700}
.sJ .jrad{margin-top:auto;border-left:6px solid var(--rain);padding:4px 0 4px 16px;
font-size:17px;line-height:1.4;color:var(--gray)}
.sJ .jrad b{color:var(--ink);font-weight:700}

.sJ .jleg{display:flex;flex-wrap:wrap;gap:6px 22px;margin-top:16px}
.sJ .jleg span{display:flex;align-items:center;gap:8px;font-family:'Archivo';font-weight:700;
font-size:15px;color:var(--gray);letter-spacing:.2px}
.sJ .jleg i{width:14px;height:14px;border-radius:50%;display:block;flex:none}


`;

// ============================================================================================
// SLIDES · estructura por pasos.
//   1 · los cinco pasos, con su función y su fuente
//   2 · desglose del mapa de daño físico
//   3 · desglose del mapa de afectación económica
//   4 · ubicación del cliente: distrito, punto, radio y cuenca cercana
//   5 · ejemplo numérico de punta a punta
// ============================================================================================

const s1 = `<section class="slide sP">
  <div class="mark"></div>
  <div class="pad">
    <div class="kick rv d1"><span class="sq"></span>FEN · Riesgo de Crédito · Metodología</div>
    <h1 class="rv d1">Los cinco pasos, <em>de los insumos a la PD</em></h1>
    <div class="rule rv d1"><i></i></div>

    <div class="pasos rv d2">
      <div class="ps">
        <div class="pn">1</div>
        <div class="pq"><b>Atribución</b> = f ( daño histórico de la cuenca , años que fueron El Niño )</div>
        <div class="pd2">¿Qué parte del daño se explica por El Niño y no por la lluvia de todos los años?</div>
        <div class="pf">DesInventar 1970-2015 · INDECI 2003-2020 · ICEN del IGP</div>
      </div>
      <div class="ps">
        <div class="pn">2</div>
        <div class="pq"><b>Daño físico</b> = f ( severidad , recurrencia , fragilidad , exposición , <i>atribución</i> )</div>
        <div class="pd2">Cuánto destruye el agua cuando llega: vivienda, comercio y vías.</div>
        <div class="pf">DesInventar · INDECI · SINPAD 2019-2026 · CENEPRED · cuencas del ANA</div>
      </div>
      <div class="ps">
        <div class="pn">3</div>
        <div class="pq"><b>Afectación económica</b> = f ( actividad económica del distrito , sector del cliente )</div>
        <div class="pd2">A quién se le rompe el ingreso, y a quién no.</div>
        <div class="pf">Censo 2017, PEA por rama · SINPAD, daño agropecuario · IMARPE y PRODUCE, pesca</div>
      </div>
      <div class="ps">
        <div class="pn">4</div>
        <div class="pq"><b>Rezago de recuperación</b> = f ( consumo regional , su propia tendencia )</div>
        <div class="pd2">Cuánto <b>le falta</b> a la región para volver a su nivel. Positivo = recupera lento = más estrés.</div>
        <div class="pf">Índice IBK+ · alternativa con 25 departamentos: INEI o BCRP</div>
      </div>
      <div class="ps">
        <div class="pn">5</div>
        <div class="pq"><b>Escenario</b> = f ( pronóstico ENFEN , mes del año )</div>
        <div class="pd2">De qué magnitud será el evento y cuánta información tenemos hoy.</div>
        <div class="pf">Comunicados ENFEN · serie ICEN 1950-2025</div>
      </div>
    </div>

    <div class="pout rv d4">
      <div class="peq"><b>PD estresada</b> = F ( <u>PD calibrada</u> , <i>daño físico</i> , <i>afectación económica</i> , <i>rezago de recuperación</i> , <i>escenario</i> )</div>
      <div class="pn2">La <u>PD calibrada</u> entra intacta. El overlay se aplica <b>después</b> de la calibración.</div>
    </div>
  </div>
</section>`;

const s2 = `<section class="slide sM">
  <div class="mark"></div>
  <div class="pad">
    <div class="kick rv d1"><span class="sq"></span>Paso 2 · Mapa de daño físico</div>
    <h1 class="rv d1">Dónde el agua <em class="r">destruye el activo</em></h1>
    <div class="rule rv d1"><i></i></div>

    <div class="mbody rv d2">
      <div>${mapa('rn', RAMP_R)}</div>
      <div class="mcol">
        <div class="mfx"><b>Daño físico</b> = f ( severidad , recurrencia , fragilidad , exposición , atribución )</div>

        <table class="mt">
          <tr><th>componente</th><th>qué mide</th><th>fuente</th></tr>
          <tr><td>Severidad</td><td>damnificados y viviendas destruidas</td><td>DesInventar 83 y 98 · INDECI 2017</td></tr>
          <tr><td>Recurrencia</td><td>en cuántos de los 4 eventos se activó</td><td>DesInventar · INDECI · SINPAD</td></tr>
          <tr><td>Fragilidad</td><td>activación en eventos recientes</td><td>SINPAD 2017 y 2023-24</td></tr>
          <tr><td>Exposición</td><td>% de población en zona inundable</td><td>CENEPRED, escenario FEN 2023</td></tr>
          <tr><td><b>Atribución</b></td><td>concentración del daño en años El Niño</td><td>cuencas del ANA · ICEN del IGP</td></tr>
        </table>

        <div class="mk">
          <div><b class="r">${nR[4]+nR[5]}</b><span>distritos en riesgo alto,<br>de 1.891</span></div>
          <div><b>+0,50</b><span>correlación con el daño<br>por habitante de 2017</span></div>
          <div><b>−0,04</b><span>correlación de la pobreza<br>con el mismo daño</span></div>
        </div>
      </div>
    </div>

    <div class="cierre rv d4">Ventana: <em class="r">enero a abril</em>, vertiente del Pacífico.
      <span>La atribución evita marcar cuencas que se inundan todos los años con o sin El Niño.</span></div>
  </div>
</section>`;

const s3 = `<section class="slide sM">
  <div class="mark"></div>
  <div class="pad">
    <div class="kick rv d1"><span class="sq"></span>Paso 3 · Mapa de afectación económica</div>
    <h1 class="rv d1">A quién <em>se le rompe el ingreso</em></h1>
    <div class="rule rv d1"><i></i></div>

    <div class="mbody rv d2">
      <div>${mapa('an', RAMP_A)}</div>
      <div class="mcol">
        <div class="mfx"><b>Afectación económica</b> = f ( actividad económica del distrito , sector del cliente )</div>

        <table class="mt">
          <tr><th>canal</th><th>a quién alcanza</th><th>fuente</th></tr>
          <tr><td>Pesca</td><td>se cierra la temporada de anchoveta</td><td>IMARPE · PRODUCE</td></tr>
          <tr><td>Agricultura</td><td>se pierde la campaña</td><td>SINPAD · Censo 2017</td></tr>
          <tr><td>Ganadería</td><td>se pierde el pasto y el hato</td><td>SINPAD · Censo 2017</td></tr>
          <tr><td>Agroexportación</td><td>el calor impide la floración</td><td>ADEX · SENAMHI agroclimático</td></tr>
          <tr><td><b>Construcción</b></td><td><b>gana: la reconstrucción le da trabajo</b></td><td>MEF · BCRP</td></tr>
        </table>

        <div class="mk">
          <div><b class="g">${un(haTot)} M</b><span>hectáreas y ${un(ganTot)} M de<br>cabezas ya dañadas</span></div>
          <div><b class="r">−57%</b><span>captura de anchoveta<br>en El Niño costero</span></div>
          <div><b>1.891</b><span>distritos con PEA<br>por rama, sin huecos</span></div>
        </div>
      </div>
    </div>

    <div class="cierre rv d4">El multiplicador sectorial <em>puede ser negativo</em>.
      <span>Un maestro de obra en Catacaos no es un cliente de mayor riesgo por el FEN: es uno de menor riesgo. &nbsp;·&nbsp; La estructura productiva sale del <b>Censo 2017</b>, el último censo nacional: es la única fuente con los 1.891 distritos completos. ENAHO es anual pero muestral y no cubre distrito.</span></div>
  </div>
</section>`;

// ============ PASO 4 · REZAGO DE RECUPERACION (IBK+) ============
// El indice de consumo IBK+ es var. % real mensual por departamento, ene-2022 a jun-2026, 12 de 25
// departamentos. Piura durante Yaku SUBIO y siguio abriendo brecha contra el nacional hasta setiembre:
// lo que crece (construccion, materiales, reposicion) esta bancarizado y lo que cae (pesca artesanal,
// agricultura de secano, comercio informal) no lo esta. Por eso la unica lectura valida es la
// desviacion contra su PROPIA tendencia, estimada por SARIMA sobre el nivel.
const s8 = `<section class="slide sR">
  <div class="mark"></div>
  <div class="pad">
    <div class="kick rv d1"><span class="sq"></span>Paso 4 · Rezago de recuperación</div>
    <h1 class="rv d1">Cuánto tarda la zona <em>en volver</em></h1>
    <div class="rule rv d1"><i></i></div>

    <div class="rbody rv d2">
      <div class="rgraf">${gIbk()}</div>

      <div class="rcol">
        <div class="rfx"><b>Rezago</b> = f ( consumo observado , su propia tendencia )</div>
        <div class="rq">Signo <b>positivo = peor</b>, igual que los otros dos mapas: mide cuánto le
          falta a la zona para volver a donde estaba.</div>

        <div class="rt">Tres lecturas del mismo dato, tres resultados opuestos</div>
        <table class="rtb">
          <tr><td>Variación absoluta</td><td>no cae nunca</td><td class="mal">falso negativo</td></tr>
          <tr><td>Contra el nacional</td><td>sube</td><td class="mal">señal invertida</td></tr>
          <tr><td><b>Contra su propia tendencia</b></td><td><b>−0,75 pp</b></td><td class="ok">la válida</td></tr>
        </table>

        <div class="ral"><b>Piura durante Yaku subió.</b> Lo que crece —construcción, materiales,
          reposición— está bancarizado; lo que cae —pesca artesanal, agricultura de secano, comercio
          informal— no lo está. El índice mide la mitad que se beneficia.</div>

        <div class="rq2"><b>Y ese repunte es gasto financiado: parece recuperación y es
          apalancamiento.</b> Por eso entra como rezago, no como alivio.</div>
      </div>
    </div>

    <div class="cierre rv d4">Índice de consumo <em>IBK+</em>, var. % real mensual por departamento.
      <span>Ene-2022 a jun-2026, <b>12 de 25 departamentos</b> — sin Tumbes. La tendencia propia se estima
      con SARIMA sobre el nivel. Cobertura completa alternativa: Indicador de Actividad Productiva
      Departamental del INEI o la síntesis regional del BCRP.</span></div>
  </div>
</section>`;

const s4 = `<section class="slide sU">
  <div class="mark"></div>
  <div class="pad">
    <div class="kick rv d1"><span class="sq"></span>Ubicación del cliente</div>
    <h1 class="rv d1">Admisión por distrito, <em>stock por punto</em></h1>
    <div class="rule rv d1"><i></i></div>

    <div class="ubody rv d2">
      <div class="ucol">
        <div class="uh">Admisión — el lead</div>
        <div class="ufx"><b>Ubicación</b> = f ( nombre del distrito )</div>
        <div class="ub"><b>98,08%</b> por RENIEC. El domicilio es el del DNI y no hay punto para un tercio
          de la población de campaña.</div>
        <div class="ul">La decisión de admisión —otorgar, línea, plazo y precio— <b>no requiere más
          precisión que el distrito</b>.</div>

      </div>

      <div class="ucol">
        <div class="uh">Stock — el cliente</div>
        <div class="ufx"><b>Ubicación</b> = f ( latitud , longitud )</div>
        <div class="ub"><b>75,88%</b> con punto censal. Foto 2017, cae 0,4 pp por mes.</div>

        <div class="upaso"><b>a · El radio se mide desde el cauce</b><br>
          <span class="ufx2">micro = f ( distancia al cauce , altura sobre el cauce )</span>
          <span class="ud">No es un círculo alrededor del cliente: es una <b>franja a lo largo del cauce
          que se activa</b>. Menos de <b>500 m</b> y menos de <b>10 m</b> de altura sobre él → corredor.
          Hasta <b>2 km</b> y <b>25 m</b> → interpolado. Fuera → promedio del distrito.</span></div>

        <div class="upaso"><b>b · Qué cauce, y cuándo cuenta</b><br>
          <span class="ufx2">cauce = f ( punto ) &nbsp;·&nbsp; peso = f ( atribución El Niño de su cuenca )</span>
          <span class="ud">La <b>quebrada</b> es la unidad correcta, no la cuenca: la cuenca es
          <b>2,7× más grande que el distrito</b> y no discrimina. La cuenca entra sólo como <b>peso</b> —
          cuánto de su daño ocurre en años El Niño— no como ubicación.</span></div>
      </div>
    </div>

    <div class="cierre rv d4">El total del distrito <em>no cambia</em>: el punto sólo redistribuye adentro.
      <span>Falta el punto en 25% de las zonas de riesgo alto contra 16% en Lima; sin esa regla el overlay
      sería más preciso en Lima que en Piura.</span></div>
  </div>
</section>`;

const s5 = `<section class="slide sE">
  <div class="mark"></div>
  <div class="pad">
    <div class="kick rv d1"><span class="sq"></span>Ejemplo · de punta a punta</div>
    <h1 class="rv d1">El mismo distrito, <em>distinto cliente</em></h1>
    <div class="rule rv d1"><i></i></div>

    <div class="ebody rv d2">
      <table class="et">
        <tr>
          <th>perfil</th><th>PD<br>calibrada</th><th>daño<br>físico</th><th>afectación<br>económica</th>
          <th>rezago de<br>recuperación</th><th>ajuste<br>total</th><th class="hi">PD hoy<br>agosto · 18%</th>
          <th class="hi2">PD en<br>ene-abr · 100%</th>
        </tr>
        <tr>
          <td><b>Chimbote</b> · pescador</td><td>7,5%</td><td>+2,36</td><td>+1,50</td><td>+0,20</td>
          <td>+0,49</td><td class="hi">8,70%</td><td class="hi2">16,04%</td></tr>
        <tr>
          <td><b>Chimbote</b> · empleado público</td><td>7,5%</td><td>+2,36</td><td>0,00</td><td>+0,20</td>
          <td>+0,34</td><td class="hi">8,58%</td><td class="hi2">14,96%</td></tr>
        <tr>
          <td><b>Catacaos</b> · comerciante con local</td><td>6,0%</td><td>+2,10</td><td>+1,00</td><td>+0,40</td>
          <td>+0,41</td><td class="hi">6,96%</td><td class="hi2">12,89%</td></tr>
        <tr>
          <td><b>San Isidro</b> · empleado</td><td>3,0%</td><td>−1,66</td><td>0,00</td><td>−0,10</td>
          <td>−0,24</td><td class="hi">3,29%</td><td class="hi2">4,93%</td></tr>
      </table>

      <div class="elee">
        <div><b>Mismo distrito, distinto sector.</b> En Chimbote el pescador termina en <b>16,04%</b> y el
          empleado público en <b>14,96%</b>: el sector explica <b>1,1 puntos</b>.</div>
        <div><b>El peso del mes manda.</b> Hoy el movimiento es chico porque en agosto sólo conocemos el
          <b>18%</b> del escenario. En temporada se aplica completo.</div>
        <div><b>Todos suben, a distinta velocidad.</b> San Isidro también sube porque el escenario mueve la
          PD del banco; lo que reparte el score es <b>cuánto más</b>, no la dirección.</div>
      </div>
    </div>

    <div class="cierre rv d4">Los pesos del ejemplo son <em>ilustrativos</em>, no calibrados.
      <span>Se estiman del spread observado entre zonas en 2017 y 2023, dentro de la caja que garantiza que
      el ajuste nunca se desborde.</span></div>
  </div>
</section>`;

// ============ SLIDE · EJEMPLO GEOGRAFICO EN UN DISTRITO GRANDE ============
// San Juan de Lurigancho: 12,9 x 19,5 km, cruza dos cuencas. 736 celdas de cartera de la grilla
// de Lima (~275 m) del heatmap existente, clasificadas por cuenca con point-in-polygon.
// Hallazgo: 99,7% de la cartera cae en Rimac. El refinamiento POR CUENCA no paga; lo que haria
// falta es la capa de centro poblado, que hoy no esta georreferenciada.
// ============ GRÁFICO · Olmos y SJL: centros poblados sobre las cuencas ============
// Olmos: los 118 centros poblados de CENEPRED, georreferenciados cruzando su código INEI con el
// directorio nacional del INEI. Encima, las cuencas que cruzan el distrito, con el Cascajal
// resaltado: es donde caen 93 de los 118 y es el río que lo inundó en 2017 y en 1998.
// SJL al lado como contraste: un solo centro poblado para 1.038.495 personas.
function gEj(cual){
  const E = JSON.parse(fs.readFileSync(B + '/03_deck/_ej.json', 'utf8'));
  const d = E[cual];
  const [x0, y0, x1, y1] = d.bx;
  const w = 430, h = 430, pad = 24;
  const kx = Math.cos((y0 + y1) / 2 * Math.PI / 180);
  const sc = Math.min((w - 2 * pad) / ((x1 - x0) * kx), (h - 2 * pad) / (y1 - y0));
  const cx = (w - ((x1 - x0) * kx * sc)) / 2, cy = (h - ((y1 - y0) * sc)) / 2;
  const X = lo => cx + (lo - x0) * kx * sc, Y = la => cy + (y1 - la) * sc;
  const col = ['#c6ccd3', '#ffe08a', '#ffb347', '#e8642a', '#a8140f'];
  let s = '<svg viewBox="0 0 ' + w + ' ' + h + '" class="gr">';
  const anillo = d.ring.map(p => X(p[0]).toFixed(1) + ' ' + Y(p[1]).toFixed(1)).join('L');
  if (cual === 'olmos') {
    // las cuencas se recortan al polígono del distrito para que no invadan el resto del lienzo
    s += '<clipPath id="cpOl"><path d="M' + anillo + 'Z"/></clipPath><g clip-path="url(#cpOl)">';
    E.cuencas.forEach(c => {
      const cas = /Cascajal/.test(c.n);
      s += '<path d="M' + c.r.map(p => X(p[0]).toFixed(1) + ' ' + Y(p[1]).toFixed(1)).join('L') + 'Z" fill="#1b6ec2" fill-opacity="' + (cas ? '.13' : '0') + '" stroke="#1b6ec2" stroke-width="' + (cas ? '2.4' : '1.4') + '" stroke-dasharray="' + (cas ? '0' : '4 3') + '"/>';
    });
    s += '</g>';
  }
  s += '<path d="M' + anillo + 'Z" fill="none" stroke="#111" stroke-width="2.6"/>';
  if (cual === 'olmos') {
    // el cauce del Cascajal, y el radio referencial anclado SOBRE EL CAUCE, no sobre la poblacion:
    // el origen del peligro es el rio, no el centro poblado
    const CAS = CORR.olmos.d.cauces['Río Cascajal'] || [];
    CAS.forEach(l => { s += '<path d="M' + l.map(p => X(p[0]).toFixed(1) + ' ' + Y(p[1]).toFixed(1)).join('L') + '" fill="none" stroke="#0b4d8f" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/>'; });
    const V = CAS.flat().filter(p => { const a = X(p[0]), b = Y(p[1]); return a > 60 && a < w - 60 && b > 60 && b < h - 60; });
    const ref = V.length ? V[Math.floor(V.length * 0.5)] : d.pts.filter(p => p[2] >= 3).sort((a, b) => b[3] - a[3])[0];
    const r5 = (5 / 111.32) * sc;
    s += '<circle cx="' + X(ref[0]).toFixed(1) + '" cy="' + Y(ref[1]).toFixed(1) + '" r="' + r5.toFixed(1) + '" fill="none" stroke="#111" stroke-width="1.8" stroke-dasharray="5 4"/>';
    s += '<text x="' + (X(ref[0]) + r5 + 7).toFixed(1) + '" y="' + (Y(ref[1]) + 4).toFixed(1) + '" class="gk gh" fill="#111">5 km desde el cauce</text>';
  }
  d.pts.slice().sort((a, b) => a[2] - b[2]).forEach(p => {
    const r = cual === 'sjl' ? 12 : (p[2] >= 3 ? 4.4 : 3.1);
    s += '<circle cx="' + X(p[0]).toFixed(1) + '" cy="' + Y(p[1]).toFixed(1) + '" r="' + r + '" fill="' + col[p[2]] + '" stroke="#fff" stroke-width="1.2"/>';
  });
  s += '</svg>'; return s;
}

// ============ GRÁFICO · SJL: el corredor del cauce ============
// Borde del distrito: relacion 1944815 de OpenStreetMap, 427 vertices (el geojson distrital que
// usamos en los mapas nacionales trae SJL con 11 vertices y no sirve a esta escala).
// Cauces: Rio Rimac y Quebrada Huaycoloro, lineas de OpenStreetMap. El Huaycoloro va punteado
// porque OSM lo marca intermittent=yes: seco casi todo el ano, es el que baja en El Nino.
// Malla de 336 x 307 m recortada al distrito (1.374 celdas). Para cada celda: distancia al cauce
// mas cercano y altura sobre el punto de cauce mas cercano (HAND), con elevacion SRTM 30 m.
// ============ GRAFICO · el corredor del cauce, identico para los dos distritos ============
// Bordes distritales y cauces: OpenStreetMap. Elevacion: SRTM 30 m via OpenTopoData.
// Para cada celda de la malla: distancia al cauce mas cercano y altura sobre ese cauce (HAND).
// El radio referencial se ancla SOBRE EL CAUCE —el origen del peligro— no sobre la poblacion.
const CORR = {
  sjl:  { d: JSON.parse(fs.readFileSync(B + '/03_deck/_sjl_cauce.json', 'utf8')),
          w: 330, h: 452, esc: 5, ancla: 'confluencia', ptos: true,
          cauces: [['Río Rímac', ''], ['Quebrada Huaycoloro', 'stroke-dasharray="6 4"']] },
  olmos:{ d: JSON.parse(fs.readFileSync(B + '/03_deck/_ol_cauce.json', 'utf8')),
          w: 330, h: 452, esc: 25, ancla: 'medio', ptos: false,
          cauces: [['Río Cascajal', ''], ['Río Olmos', 'stroke-dasharray="6 4"']] }
};
function gCorr(cual){
  const C = CORR[cual], D = C.d, [x0,y0,x1,y1] = D.bb, w = C.w, h = C.h, pad = 16;
  const kx = Math.cos((y0+y1)/2*Math.PI/180);
  const sc = Math.min((w-2*pad)/((x1-x0)*kx), (h-2*pad)/(y1-y0));
  const cx = (w-((x1-x0)*kx*sc))/2, cy = (h-((y1-y0)*sc))/2;
  const X = lo => cx+(lo-x0)*kx*sc, Y = la => cy+(y1-la)*sc, km = k => (k/111.32)*sc;
  const dx = (D.cw/(111.32*kx))*kx*sc, dy = (D.ch/111.32)*sc;
  const anillo = D.ring.map(p => X(p[0]).toFixed(1)+' '+Y(p[1]).toFixed(1)).join('L');
  let s = '<svg viewBox="0 0 '+w+' '+h+'" class="gr">';
  // el distrito entero, en el azul del agua: es lo que hoy marca la cuenca, sin distinguir nada adentro
  s += '<path d="M'+anillo+'Z" fill="#1b6ec2" fill-opacity=".13" stroke="#1b6ec2" stroke-width="1.6" stroke-dasharray="4 3"/>';
  s += '<clipPath id="cp'+cual+'"><path d="M'+anillo+'Z"/></clipPath><g clip-path="url(#cp'+cual+')">';
  D.cells.forEach(c => {
    const cerca = c[2] <= 500, bajo = c[3] <= 10;
    let f = null;
    if (cerca && bajo) f = '#a8140f';       // el corredor: pasa los dos filtros
    else if (cerca)    f = '#ffb347';       // cerca del cauce pero por encima del agua
    else if (bajo)     f = '#ffe9b8';       // a la altura del agua pero lejos del cauce
    if (!f) return;
    s += '<rect x="'+(X(c[0])-dx/2).toFixed(1)+'" y="'+(Y(c[1])-dy/2).toFixed(1)+'" width="'+(dx+0.6).toFixed(1)+'" height="'+(dy+0.6).toFixed(1)+'" fill="'+f+'"/>';
  });
  s += '</g>';
  const linea = (l, st) => '<path d="M'+l.map(p => X(p[0]).toFixed(1)+' '+Y(p[1]).toFixed(1)).join('L')+'" fill="none" stroke="#0b4d8f" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round" '+st+'/>';
  C.cauces.forEach(([nm, st]) => (D.cauces[nm]||[]).forEach(l => { s += linea(l, st); }));
  s += '<path d="M'+anillo+'Z" fill="none" stroke="#111" stroke-width="2.6"/>';
  // ---- radio referencial, anclado SOBRE EL CAUCE ----
  const A = (D.cauces[C.cauces[0][0]]||[]).flat(), Bc = (D.cauces[C.cauces[1][0]]||[]).flat();
  let anc = A[0];
  if (C.ancla === 'confluencia' && A.length && Bc.length) {
    const boca = Bc.reduce((a,b) => a[1] < b[1] ? a : b); let bd = 1e9;
    A.forEach(p => { const d = (p[0]-boca[0])**2 + (p[1]-boca[1])**2; if (d < bd) { bd = d; anc = p; } });
  } else {
    const v = A.filter(p => { const a = X(p[0]), b = Y(p[1]);
      return a > km(2)+22 && a < w-km(2)-22 && b > km(2)+22 && b < h-km(2)-22; });
    anc = v.length ? v[Math.floor(v.length*0.45)] : A[Math.floor(A.length/2)];
  }
  const ax = X(anc[0]), ay = Y(anc[1]);
  s += '<circle cx="'+ax.toFixed(1)+'" cy="'+ay.toFixed(1)+'" r="'+km(2).toFixed(1)+'" fill="none" stroke="#111" stroke-width="1.8" stroke-dasharray="5 4"/>';
  s += '<circle cx="'+ax.toFixed(1)+'" cy="'+ay.toFixed(1)+'" r="'+Math.max(km(0.5), 2.2).toFixed(1)+'" fill="none" stroke="#a8140f" stroke-width="2.2"/>';
  const der = ax < w/2, lx = der ? ax+km(2)+7 : ax-km(2)-7, an = der ? 'start' : 'end';
  const cl = (txt, x, an2) => an2==='end' ? Math.max(x, txt.length*9.4+4) : Math.min(x, w-txt.length*9.4-4);
  s += '<text x="'+cl('500 m · corredor',lx,an).toFixed(1)+'" y="'+(ay-16).toFixed(1)+'" class="gk gh" text-anchor="'+an+'" fill="#a8140f">500 m · corredor</text>';
  s += '<text x="'+cl('2 km · interpolado',lx,an).toFixed(1)+'" y="'+(ay-2).toFixed(1)+'" class="gk gh" text-anchor="'+an+'" fill="#111">2 km · interpolado</text>';
  const bx0 = pad+4, by0 = pad+18, L = km(C.esc);
  s += '<line x1="'+bx0+'" y1="'+by0+'" x2="'+(bx0+L).toFixed(1)+'" y2="'+by0+'" stroke="#111" stroke-width="2.4"/>';
  s += '<line x1="'+bx0+'" y1="'+(by0-4)+'" x2="'+bx0+'" y2="'+(by0+4)+'" stroke="#111" stroke-width="2.4"/>';
  s += '<line x1="'+(bx0+L).toFixed(1)+'" y1="'+(by0-4)+'" x2="'+(bx0+L).toFixed(1)+'" y2="'+(by0+4)+'" stroke="#111" stroke-width="2.4"/>';
  s += '<text x="'+(bx0+L/2).toFixed(1)+'" y="'+(by0-8)+'" class="gk gh" fill="#111" text-anchor="middle">'+C.esc+' km</text>';
  // el rotulo de cada cauce va sobre un vertice que caiga dentro del lienzo: los rios se extienden
  // mucho mas alla del marco del distrito y anclarlos a un vertice cualquiera los deja fuera de vista
  C.cauces.forEach(([nm], i) => {
    const v = (D.cauces[nm]||[]).flat().filter(p => { const a = X(p[0]), b = Y(p[1]); return a > 30 && a < w-30 && b > 30 && b < h-30; });
    if (!v.length) return;
    const p = v[Math.floor(v.length*(i ? 0.30 : 0.16))];
    const et = nm.replace('Río ','').replace('Quebrada ','Q. '), aa = i?'start':'end';
    s += '<text x="'+cl(et, X(p[0])+(i?9:-8), aa).toFixed(1)+'" y="'+(Y(p[1])+(i?4:15)).toFixed(1)+'" class="gk gh" fill="#0b4d8f" text-anchor="'+aa+'">'+et+'</text>';
  });
  return s + '</svg>';
}

const s6 = `<section class="slide sJ">
  <div class="mark"></div>
  <div class="pad">
    <div class="kick rv d1"><span class="sq"></span>Ubicación del stock · cómo se define el radio</div>
    <h1 class="rv d1">El radio se mide <em>desde el cauce</em></h1>
    <div class="rule rv d1"><i></i></div>

    <div class="ejbody tres rv d2">

      <div class="ejp">
        <div class="ejh">San Juan de Lurigancho<u>valle andino · 188 a 2.184 m</u></div>
        <div class="ejmap alto">${gCorr('sjl')}</div>
      </div>

      <div class="ejp">
        <div class="ejh">Olmos<u>llanura costera · −4 a 1.157 m</u></div>
        <div class="ejmap alto">${gCorr('olmos')}</div>
      </div>

      <div class="ejcol">
        <div class="ejt">La función</div>
        <div class="ejfx">micro = f ( distancia al cauce , altura sobre el cauce )</div>
        <div class="ejq">No es un círculo alrededor del cliente. Es una <b>franja a lo largo del cauce
          que se activa</b>, y dentro de ella sólo lo que está <b>a la altura del agua</b>. El radio se
          ancla en el <b>cauce</b>, que es el origen del peligro, no en la población.</div>

        <div class="ejt2">Cuánto del distrito queda marcado</div>
        <table class="ejtb dos">
          <tr><th></th><th>Lurigancho</th><th>Olmos</th></tr>
          <tr><td>Lo que marca <b>la cuenca</b></td><td>100%</td><td>100%</td></tr>
          <tr><td>≤ 10 m sobre el cauce</td><td>6,6%</td><td>68,0%</td></tr>
          <tr><td>≤ 500 m del cauce</td><td>2,7%</td><td>5,3%</td></tr>
          <tr><td><b>El corredor</b></td><td><b>1,7%</b></td><td><b>4,9%</b></td></tr>
          <tr><td>en km²</td><td>2,5 de 142</td><td>263 de 5.370</td></tr>
        </table>

        <div class="ejal">Por eso van <b>las dos condiciones</b>. En el valle manda la <b>altura</b>:
          el radio solo sobre-marca <b>35%</b>. En la llanura manda el <b>radio</b>: la altura casi no
          filtra —el 68% del distrito está a nivel del cauce— y sobre-marca <b>7%</b>.</div>

        <div class="ejq2">Una sola de las dos reglas falla en uno de los dos terrenos. La cuenca falla
          en ambos: marca el <b>100%</b> del distrito y no distingue nada adentro.</div>
      </div>
    </div>

    <div class="ejleg pie rv d3">
      <span><i style="background:#a8140f"></i> <b>el corredor</b> · cumple las dos</span>
      <span><i style="background:#ffb347"></i> cerca del cauce pero por encima del agua</span>
      <span><i style="background:#ffe9b8"></i> a la altura del agua pero lejos del cauce</span>
      <span><i class="ln"></i> cauce</span>
      <span><i class="cu"></i> distrito · lo que marca la cuenca</span>
      <span><i class="ra"></i> radio referencial sobre el cauce</span>
    </div>

    <div class="cierre rv d4">Cauces y bordes distritales de <em>OpenStreetMap</em>; altitud de <em>SRTM 30 m</em>.
      <span>Malla de 336 × 307 m en Lurigancho y 1.847 × 1.757 m en Olmos. El borde de Olmos calza con el
      INEI (5.358 contra 5.361 km²); el de Lurigancho encierra 142 km² contra los 131 km² publicados.</span></div>
  </div>
</section>`;

const s7 = `<section class="slide sJ">
  <div class="mark"></div>
  <div class="pad">
    <div class="kick rv d1"><span class="sq"></span>Ejemplo geográfico · por qué un distrito queda marcado</div>
    <h1 class="rv d1">Olmos no está cerca del río: <em>está adentro</em></h1>
    <div class="rule rv d1"><i></i></div>

    <div class="ejbody two rv d2">

      <div class="ejp">
        <div class="ejh">Olmos · Lambayeque<u>114 × 107 km · 118 centros poblados · R4</u></div>
        <div class="ejmap cuad">${gEj('olmos')}</div>
        <div class="ejleg">
          <span><i style="background:#a8140f"></i> Muy alto 4</span>
          <span><i style="background:#e8642a"></i> Alto 65</span>
          <span><i style="background:#ffb347"></i> Medio 40</span>
          <span><i style="background:#ffe08a"></i> Bajo 9</span>
          <span><i class="cu"></i> cuencas · relleno = Cascajal</span>
          <span><i class="ln"></i> cauce del Cascajal</span>
          <span><i class="ra"></i> radio sobre el cauce</span>
        </div>
        <div class="ejn"><b>16.034</b> personas en exposición Alta o Muy alta contra <b>24.952</b> en
          Baja o Media. <b>39% contra 61% dentro del mismo distrito.</b></div>
      </div>

      <div class="ejcol">
        <div class="ejt">Dónde caen sus centros poblados</div>
        <div class="ejq"><b>93 de sus 118</b> centros poblados caen en la <b>cuenca Cascajal</b> — el
          río que lo dejó incomunicado en 2017 y que ya lo había hecho en 1998.</div>
        <table class="ejtb">
          <tr><td>Cuenca Cascajal</td><td><b>93</b></td><td>58 en alta</td></tr>
          <tr><td>Cuenca Olmos</td><td>18</td><td>7 en alta</td></tr>
          <tr><td>Intercuenca 137779</td><td>4</td><td>4 en alta</td></tr>
          <tr><td>Cuenca Piura</td><td>3</td><td>0</td></tr>
        </table>
        <div class="ejal"><b>El distrito toca seis cuencas y la tabla le asigna una:</b>
          «Cuenca Olmos», que tiene un solo distrito. El Cascajal, donde vive el 79% de sus centros
          poblados, <b>no existe en la tabla</b>.</div>
        <div class="ejq2">Es el mismo distrito que el gate excluía por error al inicio del proyecto.
          Con el techo corregido quedó en <b>R4</b> — y ahora se ve por qué. Aquí el refinamiento sí
          paga: <b>118 unidades</b> dentro de un distrito de 5.336 km².</div>
      </div>
    </div>

    <div class="cierre rv d4">Centros poblados de <em>CENEPRED</em> georreferenciados con el directorio del
      <em>INEI</em>; cuencas del <em>ANA</em>.
      <span>Mediana de 269 habitantes por centro poblado en los distritos de riesgo alto. En los conos de Lima
      el directorio trae entre uno y cinco: ahí el refinamiento es el corredor del cauce, no el centro poblado.</span></div>
  </div>
</section>`;

// ============ CRONOGRAMA ============
// Dias habiles L-V, 10 por frente. Feriado del periodo: Santa Rosa de Lima, 30 de agosto,
// que en 2026 cae domingo y no descuenta ningun habil.
const s9 = `<section class="slide sT">
  <div class="mark"></div>
  <div class="pad">
    <div class="kick rv d1"><span class="sq"></span>Cronograma · agosto 2026</div>
    <h1 class="rv d1">Roadmap <em>calibración × FEN</em></h1>
    <div class="rule rv d1"><i></i></div>

    <div class="tgraf rv d2">${gCron()}</div>

    <div class="tbody rv d3">
      <table class="ttb">
        <tr>
          <th>frente</th><th>arranque</th><th>cierre</th><th>hábiles</th><th>responsable</th>
        </tr>
        <tr class="gate">
          <td><b>Framework calibración × FEN</b></td><td>lun 3 ago</td><td><b>vie 7 ago</b></td><td>4</td>
          <td>Carlos Acosta</td></tr>
        <tr class="est">
          <td><b>Calibración TC No Bank</b></td><td>lun 3 ago</td><td>lun 10 ago <i>est.</i></td><td>5</td>
          <td>Carlos Acosta</td></tr>
        <tr>
          <td><b>Adm VC Cash PP</b></td><td>lun 10 ago</td><td>vie 21 ago</td><td>10</td>
          <td>Carlos Acosta</td></tr>
        <tr>
          <td><b>Adm TC Bank</b></td><td>lun 10 ago</td><td>vie 21 ago</td><td>10</td>
          <td><b>Adrián Kashimirho</b> · préstamos, estrategias</td></tr>
        <tr>
          <td><b>Stock VC</b> · PP y TC</td><td>mié 12 ago</td><td>mar 25 ago</td><td>10</td>
          <td>Carlos Acosta</td></tr>
      </table>

      <div class="tcol">
        <div class="tt">Backlog de calibraciones · sin fecha</div>
        <table class="btb">
          <tr><td><b>IL New Bank</b><span>nunca se ha calibrado</span></td><td class="tbd">TBD</td></tr>
          <tr><td><b>Comportamental BN</b><span>en evaluación</span></td><td class="tbd">TBD</td></tr>
        </table>
        <div class="tal"><b>El framework es la compuerta: si no cierra el viernes 7, no arranca
          nada el lunes 10.</b> Con el feriado del jueves 6 quedan <b>cuatro días hábiles</b>
          para cerrarlo, no cinco.</div>
      </div>
    </div>

    <div class="cierre rv d4">Días hábiles de <em>lunes a viernes</em>; sábados y domingos sombreados en el eje.
      <span>Diez hábiles por frente = dos semanas calendario; el framework son cuatro. Feriados del período: <b>jueves 6 de agosto</b>, que sí descuenta un hábil, y <b>Santa Rosa el 30</b>, que cae domingo.</span></div>
  </div>
</section>`;

const slides = [s1, s2, s3, s8, s4, s6, s5, s9];
const html = `<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>FEN · Riesgo de Crédito</title>
<link href="https://fonts.googleapis.com/css2?family=Archivo:wght@500;600;800;900&family=Nunito:wght@400;600;700&family=JetBrains+Mono:wght@400;700&display=swap" rel="stylesheet">
<style>${css}</style></head><body>
${defs}
<div class="deck-viewport"><div class="deck-stage">
${slides.join('\n')}
</div></div>
<div class="deck-controls"><button onclick="show(cur-1)">‹ Anterior</button>
<span class="cnt">1 / ${slides.length}</span>
<div class="dots">${slides.map((_,i)=>'<i onclick="show('+i+')"></i>').join('')}</div>
<button onclick="show(cur+1)">Siguiente ›</button></div>
<script>
function fitStage(){const st=document.querySelector('.deck-stage');
  const s=Math.min(innerWidth/1920,innerHeight/1080);
  st.style.transform='translate('+((innerWidth-1920*s)/2)+'px,'+((innerHeight-1080*s)/2)+'px) scale('+s+')';}
addEventListener('resize',fitStage);fitStage();
const slides=[...document.querySelectorAll('.slide')];
let cur=0;
function show(i){cur=Math.max(0,Math.min(slides.length-1,i));
  slides.forEach((s,k)=>s.classList.toggle('active',k===cur));
  document.querySelector('.cnt').textContent=(cur+1)+' / '+slides.length;
  document.querySelectorAll('.dots i').forEach((d,k)=>d.classList.toggle('on',k===cur));
  slides[cur].querySelectorAll('.rv').forEach(e=>{e.style.animation='none';e.offsetHeight;e.style.animation='';});}
addEventListener('keydown',e=>{
  if(['ArrowRight','ArrowDown',' ','PageDown'].includes(e.key)){e.preventDefault();show(cur+1);}
  if(['ArrowLeft','ArrowUp','PageUp'].includes(e.key)){e.preventDefault();show(cur-1);}
  if(e.key==='Home')show(0); if(e.key==='End')show(slides.length-1);});
let wl=false;
addEventListener('wheel',e=>{if(wl)return;if(Math.abs(e.deltaY)<18)return;wl=true;
 show(cur+(e.deltaY>0?1:-1));setTimeout(()=>{wl=false;},680);},{passive:true});
let x0=null;
addEventListener('touchstart',e=>x0=e.touches[0].clientX,{passive:true});
addEventListener('touchend',e=>{if(x0===null)return;const dx=e.changedTouches[0].clientX-x0;
 if(Math.abs(dx)>50)show(cur+(dx<0?1:-1));x0=null;},{passive:true});
show(0);
</script></body></html>`;

fs.writeFileSync(B + '/03_deck/deck_FEN_metodologia_e2e.html', html, 'utf8');
console.log('escrito: deck_FEN_metodologia_e2e.html (' + Math.round(html.length/1024) + ' KB) · ' + slides.length + ' slides');
