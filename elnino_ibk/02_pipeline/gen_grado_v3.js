'use strict';
// Taxonomía FEN-costera R0–R5 con score continuo (severidad + recurrencia + fragilidad + exposición).
// Reúne componentes por distrito de las fuentes y aplica gate Pacífico + reglas + piso CENEPRED.
const XLSX=require('xlsx');const fs=require('fs');
const B='C:/Users/CARLOS/elnino_ibk';
const {isFEN_sinpad,isFEN_desinventar}=require(B+'/02_pipeline/fen_classifier.js');
const pad=u=>String(u||'').replace(/\D/g,'').padStart(6,'0');const uq=x=>(x||'').replace(/^"|"$/g,'');
const norm=s=>uq(s).normalize('NFD').replace(/[̀-ͯ]/g,'').toUpperCase().replace(/[^A-Z0-9 ]/g,' ').replace(/\s+/g,' ').trim();
function load(f){const L=fs.readFileSync(f,'utf8').trim().split(/\r?\n/);const H=L[0].replace(/^﻿/,'').split(',');const ix={};H.forEach((h,i)=>ix[h]=i);return{rows:L.slice(1).map(l=>l.split(',')),ix};}

// 1) base distrital (ubigeo, dep, prov, dist, cuenca, vertiente) — distrito_cuenca + centroides para faltantes
const dc=load(B+'/01_inputs/geo/distrito_cuenca.csv');
const D={};const ub2cu={},cuVert={};
dc.rows.forEach(c=>{const u=pad(c[dc.ix.ubigeo]);const k=uq(c[dc.ix.cuenca_nombre]);const pac=/Pac/i.test(uq(c[dc.ix.vertiente]));
  D[u]={u,dep:uq(c[dc.ix.departamento]),prov:uq(c[dc.ix.provincia]),dist:uq(c[dc.ix.distrito]),cuenca:k,pac};ub2cu[u]=k;cuVert[k]=cuVert[k]||{P:0,O:0};cuVert[k][pac?'P':'O']++;});
// CENEPRED exposición + nombres (para faltantes)
const CE={};load(B+'/01_inputs/cenepred/cenepred_exposicion_distrito.csv').rows.forEach(c=>{const u=pad(c[0]);const pob=+c[4]||0,exp=Math.min(pob,(+c[5]||0)+(+c[7]||0));CE[u]={dep:uq(c[1]),prov:uq(c[2]),dist:uq(c[3]),pob,pct:pob>0?100*exp/pob:0};});
// recuperar faltantes (centroide -> cuenca) con _recuperados.json (ya calculado)
JSON.parse(fs.readFileSync(B+'/02_pipeline/intermedios/_recuperados.json','utf8')).forEach(r=>{if(D[r.u])return;const k=r.cuenca;D[r.u]={u:r.u,dep:r.dep,prov:(CE[r.u]||{}).prov||'',dist:r.dist,cuenca:k,pac:true};ub2cu[r.u]=k;cuVert[k]=cuVert[k]||{P:0,O:0};cuVert[k].P++;});
// override de cuenca (Chosica -> Rímac)
if(D['150118']){D['150118'].cuenca='Cuenca Rimac';ub2cu['150118']='Cuenca Rimac';}
// overrides documentados (cuenca mal-etiquetada Pfafstetter -> cuenca nombrada con severidad; + nombres rotos)
{const ov=load(B+'/02_pipeline/overrides_v3.csv');ov.rows.forEach(r=>{const u=pad(r[ov.ix.ubigeo]);if(!D[u])return;const cu=uq(r[ov.ix.set_cuenca]),pr=uq(r[ov.ix.set_prov]),di=uq(r[ov.ix.set_dist]);if(cu){D[u].cuenca=cu;ub2cu[u]=cu;}if(pr)D[u].prov=pr;if(di)D[u].dist=di;});}

// 2) activaciones: 1983/98 (DesInventar), 2017 (SINPAD-integrada), 2023-24 (SINPAD v3 nivel>=2)
const di=load(B+'/01_inputs/desinventar/desinventar_peru_1970_2015.csv');const a83={},a98={};
di.rows.forEach(c=>{if(!isFEN_desinventar(uq(c[di.ix.evento])))return;const u=pad(c[di.ix.ubigeo]);const y=+c[di.ix.year];if(y===1983)a83[u]=1;if(y===1998)a98[u]=1;});
const A=XLSX.utils.sheet_to_json(XLSX.readFile(B+'/01_inputs/sinpad/BD_emer_danos_2003_2020.xlsx').Sheets['BD 2003-2020'],{header:1,defval:null});
const a17={},dmg17={},cu17={};
A.slice(3).forEach(r=>{if(+r[2]!==2017||!isFEN_sinpad(r[8]))return;const u=pad(r[4]);a17[u]=1;dmg17[u]=(dmg17[u]||0)+(+r[13]||0);});
Object.keys(dmg17).forEach(u=>{const k=ub2cu[u];if(k)cu17[k]=(cu17[k]||0)+dmg17[u];});
// 2023-24 nivel>=2 por nombre
const name2ub={};Object.values(D).forEach(d=>{name2ub[norm(d.prov)+'|'+norm(d.dist)]=d.u;});
const a23={};for(const y of [2023,2024]){const j=JSON.parse(fs.readFileSync(B+'/01_inputs/sinpad/emergencias_'+y+'_sinpad.json','utf8'));
  for(const e of j){if(!isFEN_sinpad(e.peligroPrincipal)||(+e.nivel||0)<2)continue;const p=(e.dptoProvDistr||'').split('/');const u=name2ub[norm(p[1])+'|'+norm(p[2])];if(u)a23[u]=1;}}
// cuenca severa 1983/98
const sc=load(B+'/02_pipeline/intermedios/escenario_severo_cuenca.csv');const cuSev={};sc.rows.forEach(c=>{cuSev[uq(c[sc.ix.cuenca])]=+c[sc.ix.damnif_1983_98]||0;});

// 3) score continuo por distrito (severidad + recurrencia + fragilidad + exposición), 0–4
const out=['ubigeo,departamento,provincia,distrito,cuenca,pacifico,n_eventos,a1983,a1998,a2017,a2324,dmg17_propio,dmg_cuenca,frag_moderado,pct_expuesto,sev,rec,fra,exp_n,score,R_nivel,patron_evento'];
const rows=Object.values(D).map(d=>{
  const u=d.u;d.a83=a83[u]||0;d.a98=a98[u]||0;d.a17=a17[u]||0;d.a23=a23[u]||0;
  d.n=d.a83+d.a98+d.a17+d.a23;d.d17=dmg17[u]||0;d.d_cuenca=Math.max(cuSev[d.cuenca]||0,cu17[d.cuenca]||0);
  d.frag=(d.a17||d.a23)?1:0;d.pct=(CE[u]||{}).pct||0;
  return d;});
// topes de severidad DATA-DRIVEN: p95 de la distribución (distritos Pacífico con daño>0). Sin números mágicos.
const p95=arr=>{const v=arr.filter(x=>x>0).sort((a,b)=>a-b);return v.length?v[Math.floor(0.95*v.length)]:1;};
const capCuenca=p95(rows.filter(d=>d.pac).map(d=>d.d_cuenca));
const capD17=p95(rows.filter(d=>d.pac).map(d=>d.d17));
console.log('topes severidad p95 -> cuenca:',capCuenca,'| propio2017:',capD17);
rows.forEach(d=>{
  const sev=Math.max(Math.min(d.d_cuenca/capCuenca,1),Math.min(d.d17/capD17,1));
  const rec=d.n/4;const fra=(d.a17+d.a23)/2;const exn=d.pct/100;
  d.sev=sev;d.rec=rec;d.fra=fra;d.exn=exn;d.score=d.pac?(sev+rec+fra+exn):0;
});
// 4) niveles R1–R5 = Fisher-Jenks (k=5) sobre el score de los distritos Pacífico; R0 = no-Pacífico
function jenks(a,k){a=a.slice().sort((x,y)=>x-y);const n=a.length;const pre=[0],pr2=[0];for(let i=0;i<n;i++){pre.push(pre[i]+a[i]);pr2.push(pr2[i]+a[i]*a[i]);}
  const cost=(i,j)=>{const s=pre[j+1]-pre[i],s2=pr2[j+1]-pr2[i],c=j-i+1;return s2-s*s/c;};
  const dp=Array.from({length:n+1},()=>Array(k+1).fill(1e18)),br=Array.from({length:n+1},()=>Array(k+1).fill(0));dp[0][0]=0;
  for(let i=1;i<=n;i++)for(let j=1;j<=Math.min(k,i);j++)for(let p=j-1;p<i;p++){const v=dp[p][j-1]+cost(p,i-1);if(v<dp[i][j]){dp[i][j]=v;br[i][j]=p;}}
  const idx=[];let i=n,j=k;while(j>0){idx.unshift(br[i][j]);i=br[i][j];j--;}return idx.slice(1).map(p=>a[p]);}
const pacScores=rows.filter(d=>d.pac).map(d=>d.score);
const cuts=jenks(pacScores,5);  // 4 breaks → 5 clases
function bucket(s){let r=1;for(let i=0;i<cuts.length;i++)if(s>=cuts[i])r=i+2;return r;}
rows.forEach(d=>{d.R=d.pac?bucket(d.score):0;});
console.log('cortes Jenks score (R1|R2|R3|R4|R5):',cuts.map(x=>x.toFixed(2)));
rows.forEach(d=>out.push([d.u,'"'+d.dep+'"','"'+d.prov+'"','"'+d.dist+'"','"'+d.cuenca+'"',d.pac?1:0,d.n,d.a83,d.a98,d.a17,d.a23,Math.round(d.d17),Math.round(d.d_cuenca),d.frag,d.pct.toFixed(1),d.sev.toFixed(3),d.rec.toFixed(3),d.fra.toFixed(3),d.exn.toFixed(3),d.score.toFixed(3),'R'+d.R,(d.pac?((d.a83||d.a98)?'persistente':((d.a17||d.a23)?'reciente_solo':'sin_eventos')):'no_pac')].join(',')));
fs.writeFileSync(B+'/02_pipeline/out/grado_fen_v3.csv','﻿'+out.join('\r\n'),'utf8');
const dist={};rows.forEach(d=>dist['R'+d.R]=(dist['R'+d.R]||0)+1);
console.log('distritos:',rows.length,'| distribución R:',JSON.stringify(dist));
