'use strict';
const fs=require('fs');
const fold=s=>String(s==null?'':s).normalize('NFD').replace(/[^\x00-\x7F]/g,'').replace(/'/g,"''");
const L=fs.readFileSync(__dirname+'/out/grado_fen_v3.csv','utf8').trim().split(/\r?\n/);
const H=L[0].replace(/^﻿/,'').split(',');const ix={};H.forEach((h,i)=>ix[h]=i);
const q=s=>"'"+fold(s)+"'";
const rows=L.slice(1).map(l=>{
  const c=l.match(/(?:^|,)("(?:[^"]|"")*"|[^,]*)/g).map(s=>s.replace(/^,/,'').replace(/^"|"$/g,''));
  const ub=(c[ix.ubigeo]||'').replace(/\D/g,'').padStart(6,'0');
  const rnum=parseInt(String(c[ix.R_nivel]).replace('R',''),10)||0;
  return '('+[q(ub),q(c[ix.departamento]),q(c[ix.provincia]),q(c[ix.distrito]),q(c[ix.cuenca]),
    (+c[ix.pacifico]||0),(+c[ix.n_eventos]||0),(+c[ix.dmg_cuenca]||0),(+c[ix.pct_expuesto]||0),
    (+c[ix.score]||0),rnum,q('R'+rnum),q(c[ix.patron_evento])].join(',')+')';
});
const cols='cod_ubigeo, departamento, provincia, distrito, cuenca, pacifico, n_eventos, dmg_cuenca, pct_expuesto, score, r_nivel, r_label, patron_evento';
const sql='CREATE TABLE disc_model_owner.grado_elnino_ubigeo_v3 AS\nSELECT '+cols+' FROM (VALUES\n'+rows.join(',\n')+'\n) AS t('+cols+')';
fs.writeFileSync(__dirname+'/out/_v3_create.sql',sql,'utf8');
console.log('filas:',rows.length,'| bytes:',sql.length,'| muestra:',rows[0].slice(0,80));
