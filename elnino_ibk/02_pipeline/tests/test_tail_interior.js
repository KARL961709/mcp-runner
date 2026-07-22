'use strict';
// Dimensiona el "tail" no-Pacífico: distritos forzados a R0 por el gate que SÍ tuvieron damnificados FEN materiales.
const XLSX=require('xlsx');const fs=require('fs');
const B='C:/Users/CARLOS/elnino_ibk';
const {isFEN_sinpad,isFEN_desinventar}=require(B+'/02_pipeline/fen_classifier.js');
const pad=u=>String(u||'').replace(/\D/g,'').padStart(6,'0');const uq=x=>(x||'').replace(/^"|"$/g,'');
function loadCSV(f){const L=fs.readFileSync(f,'utf8').trim().split(/\r?\n/);const H=L[0].replace(/^﻿/,'').split(',');const ix={};H.forEach((h,i)=>ix[h]=i);
  const rows=L.slice(1).map(l=>l.match(/(?:^|,)("(?:[^"]|"")*"|[^,]*)/g).map(s=>s.replace(/^,/,'').replace(/^"|"$/g,'')));return{rows,ix};}
const dc=loadCSV(B+'/01_inputs/geo/distrito_cuenca.csv');const vert={},NM={};
dc.rows.forEach(c=>{const u=pad(c[dc.ix.ubigeo]);vert[u]=/Pac/i.test(uq(c[dc.ix.vertiente]))?'PAC':'OTRO';NM[u]=uq(c[dc.ix.departamento])+' · '+uq(c[dc.ix.provincia])+' · '+uq(c[dc.ix.distrito]);});
// max damnificados por evento por distrito (83/98/17)
const dmax={};
const acc=(u,d)=>{if(!u)return;dmax[u]=Math.max(dmax[u]||0,d);};
const di=loadCSV(B+'/01_inputs/desinventar/desinventar_peru_1970_2015.csv');const y83={},y98={};
di.rows.forEach(c=>{if(!isFEN_desinventar(uq(c[di.ix.evento])))return;const u=pad(c[di.ix.ubigeo]);const y=+c[di.ix.year];const d=+c[di.ix.damnificados]||0;
  if(y===1983)y83[u]=(y83[u]||0)+d;if(y===1998)y98[u]=(y98[u]||0)+d;});
const A=XLSX.utils.sheet_to_json(XLSX.readFile(B+'/01_inputs/sinpad/BD_emer_danos_2003_2020.xlsx').Sheets['BD 2003-2020'],{header:1,defval:null});
const y17={};A.slice(3).forEach(r=>{if(+r[2]!==2017||!isFEN_sinpad(r[8]))return;const u=pad(r[4]);y17[u]=(y17[u]||0)+(+r[13]||0);});
const all=new Set([...Object.keys(y83),...Object.keys(y98),...Object.keys(y17)]);
all.forEach(u=>acc(u,Math.max(y83[u]||0,y98[u]||0,y17[u]||0)));
// tail no-Pacífico por umbral
const TH=[1000,4000,20000];
for(const t of TH){let n=0;const list=[];for(const u in dmax){if((vert[u]||'OTRO')==='OTRO'&&dmax[u]>=t){n++;list.push([NM[u]||u,Math.round(dmax[u])]);}}
  list.sort((a,b)=>b[1]-a[1]);
  console.log('\nNo-Pacífico con max damnif >= '+t+' :  '+n+' distritos');
  console.log('  top: '+list.slice(0,8).map(([nm,d])=>nm+' ('+d.toLocaleString()+')').join('  |  '));}
// total no-Pacífico con cualquier damnif FEN
let any=0;for(const u in dmax){if((vert[u]||'OTRO')==='OTRO'&&dmax[u]>0)any++;}
console.log('\nNo-Pacífico con CUALQUIER damnif FEN >0: '+any+' distritos (hoy todos en R0)');
