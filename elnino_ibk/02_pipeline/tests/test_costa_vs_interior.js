'use strict';
// TEST de la hipótesis del gate: ¿el daño FEN se concentra en la vertiente del Pacífico?
const XLSX=require('xlsx');const fs=require('fs');
const B='C:/Users/CARLOS/elnino_ibk';
const {isFEN_sinpad,isFEN_desinventar}=require(B+'/02_pipeline/fen_classifier.js');
const pad=u=>String(u||'').replace(/\D/g,'').padStart(6,'0');const uq=x=>(x||'').replace(/^"|"$/g,'');
const norm=s=>uq(s).normalize('NFD').replace(/[̀-ͯ]/g,'').toUpperCase().replace(/[^A-Z0-9 ]/g,' ').replace(/\s+/g,' ').trim();
function loadCSV(f){const L=fs.readFileSync(f,'utf8').trim().split(/\r?\n/);const H=L[0].replace(/^﻿/,'').split(',');const ix={};H.forEach((h,i)=>ix[h]=i);
  const rows=L.slice(1).map(l=>l.match(/(?:^|,)("(?:[^"]|"")*"|[^,]*)/g).map(s=>s.replace(/^,/,'').replace(/^"|"$/g,'')));return{rows,ix};}
// vertiente + nombre por ubigeo
const dc=loadCSV(B+'/01_inputs/geo/distrito_cuenca.csv');const vert={},dep={},name2ub={};
dc.rows.forEach(c=>{const u=pad(c[dc.ix.ubigeo]);vert[u]=/Pac/i.test(uq(c[dc.ix.vertiente]))?'PAC':'OTRO';dep[u]=uq(c[dc.ix.departamento]);
  name2ub[norm(c[dc.ix.provincia])+'|'+norm(c[dc.ix.distrito])]=u;});

function report(title,acc){
  let pac=0,otro=0;const otroBy={};
  for(const u in acc){const v=vert[u]||'OTRO';if(v==='PAC')pac+=acc[u];else{otro+=acc[u];otroBy[dep[u]||'??']=(otroBy[dep[u]||'??']||0)+acc[u];}}
  const tot=pac+otro;const top=Object.entries(otroBy).sort((a,b)=>b[1]-a[1]).slice(0,5).map(([d,n])=>d+':'+Math.round(n)).join('  ');
  console.log('\n== '+title+' ==');
  console.log('  Pacífico: '+Math.round(pac).toLocaleString()+'  ('+(100*pac/tot).toFixed(1)+'%)   |   No-Pacífico: '+Math.round(otro).toLocaleString()+'  ('+(100*otro/tot).toFixed(1)+'%)');
  console.log('  Top no-Pacífico (depto): '+top);
}

// DesInventar 1983 / 1998 (damnificados FEN por distrito)
const di=loadCSV(B+'/01_inputs/desinventar/desinventar_peru_1970_2015.csv');
const a83={},a98={};
di.rows.forEach(c=>{if(!isFEN_desinventar(uq(c[di.ix.evento])))return;const u=pad(c[di.ix.ubigeo]);const y=+c[di.ix.year];const d=+c[di.ix.damnificados]||0;
  if(y===1983)a83[u]=(a83[u]||0)+d;if(y===1998)a98[u]=(a98[u]||0)+d;});
report('1983 — damnificados FEN (DesInventar)',a83);
report('1998 — damnificados FEN (DesInventar)',a98);

// SINPAD 2017 (BD 2003-2020): damnificados FEN por ubigeo
const A=XLSX.utils.sheet_to_json(XLSX.readFile(B+'/01_inputs/sinpad/BD_emer_danos_2003_2020.xlsx').Sheets['BD 2003-2020'],{header:1,defval:null});
const a17={};A.slice(3).forEach(r=>{if(+r[2]!==2017||!isFEN_sinpad(r[8]))return;const u=pad(r[4]);a17[u]=(a17[u]||0)+(+r[13]||0);});
report('2017 — damnificados FEN (SINPAD BD)',a17);

// 2023-24 (SINPAD v3 nivel>=2): CONTEO de emergencias FEN por distrito
const a23={};for(const y of [2023,2024]){const j=JSON.parse(fs.readFileSync(B+'/01_inputs/sinpad/emergencias_'+y+'_sinpad.json','utf8'));
  for(const e of j){if(!isFEN_sinpad(e.peligroPrincipal)||(+e.nivel||0)<2)continue;const p=(e.dptoProvDistr||'').split('/');const u=name2ub[norm(p[1])+'|'+norm(p[2])];if(u)a23[u]=(a23[u]||0)+1;}}
report('2023-24 — emergencias FEN nivel>=2 (conteo, SINPAD v3)',a23);
