'use strict';
// Mapa coroplético distrital R0-R5 (taxonomía FEN final). Une peru_dist.geojson <- grado_fen_v3.csv por ubigeo.
const fs=require('fs');const pad=u=>String(u||'').replace(/\D/g,'').padStart(6,'0');
const B=require('path').resolve(__dirname,'..');   // raiz elnino_ibk, portable (antes hardcodeada a C:/Users/CARLOS)
const geo=JSON.parse(fs.readFileSync(B+'/01_inputs/geo/peru_dist.geojson','utf8'));
// grado_fen_v3: ubigeo,dep,prov,dist,cuenca,pacifico,n_eventos,a1983,a1998,a2017,a2324,dmg17_propio,dmg_cuenca,frag_moderado,pct_expuesto,sev,rec,fra,exp_n,score,R_nivel
const G={};{const L=fs.readFileSync(B+'/02_pipeline/out/grado_fen_v3.csv','utf8').trim().split(/\r?\n/);const H=L[0].replace(/^﻿/,'').split(',');const ix={};H.forEach((h,i)=>ix[h]=i);
 L.slice(1).forEach(l=>{const c=l.match(/(?:^|,)("(?:[^"]|"")*"|[^,]*)/g).map(s=>s.replace(/^,/,'').replace(/^"|"$/g,''));const u=pad(c[ix.ubigeo]);
   const rn=parseInt(String(c[ix.R_nivel]).replace(/\D/g,''),10);
   G[u]={r:isNaN(rn)?0:rn,pct:Math.round(+c[ix.pct_expuesto]||0),sc:+(+c[ix.score]||0).toFixed(2),pac:+c[ix.pacifico]||0,
     nm:(c[ix.departamento]+' · '+c[ix.distrito]),cu:c[ix.cuenca]};});}
geo.features=geo.features.filter(f=>f.geometry&&f.geometry.coordinates);
let mnLo=1e9,mxLo=-1e9,mnLa=1e9,mxLa=-1e9;
const eat=r=>r.forEach(([x,y])=>{mnLo=Math.min(mnLo,x);mxLo=Math.max(mxLo,x);mnLa=Math.min(mnLa,y);mxLa=Math.max(mxLa,y);});
geo.features.forEach(f=>{if(f.geometry.type==='Polygon')f.geometry.coordinates.forEach(eat);else f.geometry.coordinates.forEach(p=>p.forEach(eat));});
const W=540,H=820,p=8;const s=Math.min((W-2*p)/(mxLo-mnLo),(H-2*p)/(mxLa-mnLa));
const px=lo=>+(p+(lo-mnLo)*s).toFixed(1),py=la=>+(p+(mxLa-la)*s).toFixed(1);
function simp(r,t){if(r.length<6)return r;const o=[r[0]];let l=r[0];for(let i=1;i<r.length-1;i++){const dx=r[i][0]-l[0],dy=r[i][1]-l[1];if(dx*dx+dy*dy>t*t){o.push(r[i]);l=r[i];}}o.push(r[r.length-1]);return o;}
function path(g){let d='';const ring=r=>{const rr=simp(r,0.012);if(rr.length<3)return;d+='M'+rr.map(([lo,la])=>px(lo)+','+py(la)).join('L')+'Z';};if(g.type==='Polygon')g.coordinates.forEach(ring);else g.coordinates.forEach(pp=>pp.forEach(ring));return d;}
const feats=geo.features.map(f=>{const m=G[pad(f.properties.IDDIST)];return {d:path(f.geometry),r:m?m.r:0,p:m?m.pct:0,sc:m?m.sc:0,nm:m?m.nm:''};});
fs.writeFileSync(__dirname+'/_slidemap_v3.json',JSON.stringify({W,H,feats}));
const c={0:0,1:0,2:0,3:0,4:0,5:0};feats.forEach(f=>c[f.r]++);
console.log('feats:',feats.length,'| KB:',(fs.statSync(__dirname+'/_slidemap_v3.json').size/1024).toFixed(0),'| R0..R5:',JSON.stringify(c));
