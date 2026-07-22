'use strict';
// Recupera (data-driven) el grado de los distritos ausentes de distrito_cuenca:
// centroide (peru_dist) -> cuenca/vertiente (spatial join cuencas.geojson) -> activación 4 eventos -> techo+posición.
const XLSX=require('xlsx');const fs=require('fs');
const B='C:/Users/CARLOS/elnino_ibk';
const {isFEN_sinpad,isFEN_desinventar}=require(B+'/02_pipeline/fen_classifier.js');
const pad=u=>String(u||'').replace(/\D/g,'').padStart(6,'0');const uq=x=>(x||'').replace(/^"|"$/g,'');
const norm=s=>uq(s).normalize('NFD').replace(/[̀-ͯ]/g,'').toUpperCase().replace(/[^A-Z0-9 ]/g,' ').replace(/\s+/g,' ').trim();
function load(f){const L=fs.readFileSync(f,'utf8').trim().split(/\r?\n/);const H=L[0].replace(/^﻿/,'').split(',');const ix={};H.forEach((h,i)=>ix[h]=i);return{rows:L.slice(1).map(l=>l.split(',')),ix};}

// 1) ubigeos faltantes
const inGrade=new Set();load(B+'/02_pipeline/intermedios/grado_integrado_v2.csv').rows.forEach(r=>inGrade.add(pad(r[0])));
const CE={};load(B+'/01_inputs/cenepred/cenepred_exposicion_distrito.csv').rows.forEach(c=>{CE[pad(c[0])]={dep:uq(c[1]),dist:uq(c[3]),pob:+c[4]||0,ih:+c[5]||0,mh:+c[7]||0};});
const missing=Object.keys(CE).filter(u=>!inGrade.has(u));

// 2) centroides desde peru_dist.geojson
const gd=JSON.parse(fs.readFileSync(B+'/01_inputs/geo/peru_dist.geojson','utf8'));
function centroid(geom){let x=0,y=0,n=0;const eat=r=>r.forEach(([a,b])=>{x+=a;y+=b;n++;});if(geom.type==='Polygon')geom.coordinates.forEach(eat);else geom.coordinates.forEach(p=>p.forEach(eat));return[x/n,y/n];}
const cen={};gd.features.forEach(f=>{if(f&&f.geometry&&f.properties&&f.properties.IDDIST)cen[pad(f.properties.IDDIST)]=centroid(f.geometry);});

// 3) spatial join a cuencas
const cu=JSON.parse(fs.readFileSync(B+'/01_inputs/geo/cuencas.geojson','utf8'));
const polys=cu.features.map(f=>{let mnx=1e9,mny=1e9,mxx=-1e9,mxy=-1e9;const eat=r=>r.forEach(([x,y])=>{if(x<mnx)mnx=x;if(x>mxx)mxx=x;if(y<mny)mny=y;if(y>mxy)mxy=y;});if(f.geometry.type==='Polygon')f.geometry.coordinates.forEach(eat);else f.geometry.coordinates.forEach(p=>p.forEach(eat));return{p:f.properties,g:f.geometry,bb:[mnx,mny,mxx,mxy]};});
function inRing(x,y,r){let c=false;for(let i=0,j=r.length-1;i<r.length;j=i++){const xi=r[i][0],yi=r[i][1],xj=r[j][0],yj=r[j][1];if(((yi>y)!==(yj>y))&&(x<(xj-xi)*(y-yi)/(yj-yi)+xi))c=!c;}return c;}
function inPoly(x,y,P){if(x<P.bb[0]||x>P.bb[2]||y<P.bb[1]||y>P.bb[3])return false;const co=P.g.coordinates;if(P.g.type==='Polygon'){let c=false;co.forEach(r=>{if(inRing(x,y,r))c=!c;});return c;}return co.some(poly=>{let c=false;poly.forEach(r=>{if(inRing(x,y,r))c=!c;});return c;});}
function findUH(u){const xy=cen[u];if(!xy)return null;for(const P of polys)if(inPoly(xy[0],xy[1],P))return P.p;return null;}

// 4) mapa ubigeo->cuenca para TODOS (existentes + recuperados) para techo de cuenca
const dc=load(B+'/01_inputs/geo/distrito_cuenca.csv');const ub2cu={},cuVert={};
dc.rows.forEach(c=>{const u=pad(c[dc.ix.ubigeo]);const k=uq(c[dc.ix.cuenca_nombre]);const pac=/Pac/i.test(uq(c[dc.ix.vertiente]));ub2cu[u]=k;cuVert[k]=cuVert[k]||{P:0,O:0};cuVert[k][pac?'P':'O']++;});
const recCuenca={};
missing.forEach(u=>{const uh=findUH(u);if(uh){const k=uh.NOMB_UH_N3||uh.NIVEL3||uh.NOMBRE||'';const pac=/Pac/i.test(uh.NOMB_UH_N1||uh.NIVEL1||'');recCuenca[u]={cuenca:k,pac};ub2cu[u]=k;cuVert[k]=cuVert[k]||{P:0,O:0};cuVert[k][pac?'P':'O']++;}else recCuenca[u]={cuenca:'(fuera)',pac:false};});
// CORRECCIÓN data-driven de asignación de cuenca para distrito grande cuyo centroide cae fuera del valle poblado:
// Lurigancho (Chosica) está en el valle del RÍMAC = UH 137 (igual que su vecino Chaclacayo=G3); el centroide cayó en los Andes altos.
// Sustento: geografía (Chosica sobre el Rímac) + activación 3/4 + CENEPRED 100% mov-masa + huaicos 2017/Yaku-2023 (prensa).
if(recCuenca['150118']){recCuenca['150118']={cuenca:'Cuenca Rímac',pac:true};ub2cu['150118']='Cuenca Rímac';}

// 5) activación. 1983/98 DesInventar; 2017 SINPAD-integrada; 2023-24 SINPAD v3 nivel>=2
const di=load(B+'/01_inputs/desinventar/desinventar_peru_1970_2015.csv');const a83={},a98={};
di.rows.forEach(c=>{if(!isFEN_desinventar(uq(c[di.ix.evento])))return;const u=pad(c[di.ix.ubigeo]);const y=+c[di.ix.year];if(y===1983)a83[u]=1;if(y===1998)a98[u]=1;});
const A=XLSX.utils.sheet_to_json(XLSX.readFile(B+'/01_inputs/sinpad/BD_emer_danos_2003_2020.xlsx').Sheets['BD 2003-2020'],{header:1,defval:null});
const act17={},dmg17={},cu17={};
A.slice(3).forEach(r=>{if(+r[2]!==2017||!isFEN_sinpad(r[8]))return;const u=pad(r[4]);act17[u]=1;dmg17[u]=(dmg17[u]||0)+(+r[13]||0);});
Object.keys(dmg17).forEach(u=>{const k=ub2cu[u];if(k)cu17[k]=(cu17[k]||0)+dmg17[u];});
const sc=load(B+'/02_pipeline/intermedios/escenario_severo_cuenca.csv');const cuSev={};sc.rows.forEach(c=>{cuSev[uq(c[sc.ix.cuenca])]=+c[sc.ix.damnif_1983_98]||0;});
// 2023-24 nivel>=2 por nombre
const name2ub={};missing.forEach(u=>{name2ub[norm(CE[u].dist)]=u;});
const a23={};for(const y of[2023,2024]){const j=JSON.parse(fs.readFileSync(B+'/01_inputs/sinpad/emergencias_'+y+'_sinpad.json','utf8'));for(const e of j){if(!isFEN_sinpad(e.peligroPrincipal)||(+e.nivel||0)<2)continue;const p=(e.dptoProvDistr||'').split('/');const u=name2ub[norm(p[2])];if(u)a23[u]=1;}}

// 6) techo + posición
function ceiling(k){const cv=cuVert[k]||{P:0,O:0};if(cv.P<cv.O)return 0;const d=Math.max(cuSev[k]||0,cu17[k]||0);if(d>=20000)return 4;if(d>=4000)return 3;if(d>=1000)return 2;if(d>0)return 1;return 0;}
function position(ct,n,d17){if(ct===0)return 0;if(n>=3||d17>=2000)return ct;if(n>=2||d17>=300)return Math.max(1,ct-1);return Math.max(1,ct-2);}

console.log('Recuperando',missing.length,'distritos ausentes\n');
console.log('ubigeo | distrito | cuenca | vert | n(83/98/17/23) | techo | GRADO | exp.real');
const res=[];
missing.sort((a,b)=>(CE[b].pob)-(CE[a].pob)).forEach(u=>{const k=recCuenca[u].cuenca;const n=(a83[u]||0)+(a98[u]||0)+(act17[u]||0)+(a23[u]||0);const ct=ceiling(k);const g=position(ct,n,dmg17[u]||0);
  const grupo=g<=2?'Bajo':g===3?'Alto':'Extremo';const e=CE[u];const exp=Math.min(e.pob,e.ih+e.mh);const pct=e.pob>0?100*exp/e.pob:0;
  res.push({u,dep:e.dep,dist:e.dist,cuenca:k,g,grupo,pob:e.pob,pct});
  if(e.pob>3000||g>=3)console.log('  '+u+' | '+(e.dep+'/'+e.dist).padEnd(26)+'| '+k.slice(0,16).padEnd(16)+'| '+(recCuenca[u].pac?'Pac':'no ')+' | '+(a83[u]||0)+'/'+(a98[u]||0)+'/'+(act17[u]||0)+'/'+(a23[u]||0)+' | T'+ct+' | G'+g+' '+grupo+' | '+pct.toFixed(0)+'%');});
fs.writeFileSync(B+'/02_pipeline/intermedios/_recuperados.json',JSON.stringify(res),'utf8');
console.log('\nGUARDADO _recuperados.json ('+res.length+'). Distribución:',JSON.stringify(res.reduce((a,r)=>{a[r.grupo]=(a[r.grupo]||0)+1;return a;},{})));
