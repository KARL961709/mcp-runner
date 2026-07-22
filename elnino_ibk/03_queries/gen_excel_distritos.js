'use strict';
// Genera Distritos_por_grupo_FEN.xlsx: roster de distritos AFECTADOS POR FEN (Pacifico, R1-R5),
// con su nivel R, grupo consolidado, score, exposicion y eventos que lo activaron. Excluye R0.
const XLSX = require('C:/Users/CARLOS/elnino_ibk/02_pipeline/node_modules/xlsx');
const fs = require('fs'); const path = require('path');
const CSV = path.join(__dirname, '..', '02_pipeline', 'out', 'grado_fen_v3.csv');
const OUT = path.join(__dirname, 'resultados'); fs.mkdirSync(OUT, { recursive: true });
const L = fs.readFileSync(CSV, 'utf8').trim().split(/\r?\n/);
const H = L[0].replace(/^﻿/, '').split(','); const ix = {}; H.forEach((h, i) => ix[h] = i);
const parse = l => l.match(/(?:^|,)("(?:[^"]|"")*"|[^,]*)/g).map(s => s.replace(/^,/, '').replace(/^"|"$/g, ''));
const grupoDe = r => (r === 'R1' ? 'G1 Bajo' : (r === 'R2' || r === 'R3' ? 'G2 Medio' : 'G3 Alto'));
const recs = L.slice(1).map(parse).filter(c => (+c[ix.pacifico] || 0) === 1).map(c => ({
  ubigeo: c[ix.ubigeo], dep: c[ix.departamento], prov: c[ix.provincia], dist: c[ix.distrito],
  cuenca: c[ix.cuenca], nivel: c[ix.R_nivel], grupo: grupoDe(c[ix.R_nivel]),
  score: +(+c[ix.score]).toFixed(3), exp_pct: +(+c[ix.pct_expuesto]).toFixed(1), n_ev: +c[ix.n_eventos] || 0,
  e1983: +c[ix.a1983] || 0, e1998: +c[ix.a1998] || 0, e2017: +c[ix.a2017] || 0, e2023_24: +c[ix.a2324] || 0,
  dmg_cuenca: Math.round(+c[ix.dmg_cuenca] || 0)
}));
// orden: grupo (Alto->Bajo), nivel desc, dep, prov, dist
const gord = { 'G3 Alto': 0, 'G2 Medio': 1, 'G1 Bajo': 2 };
recs.sort((a, b) => gord[a.grupo] - gord[b.grupo] || b.nivel.localeCompare(a.nivel) ||
  a.dep.localeCompare(b.dep) || a.prov.localeCompare(b.prov) || a.dist.localeCompare(b.dist));
const COLS = ['ubigeo', 'dep', 'prov', 'dist', 'cuenca', 'nivel', 'grupo', 'score', 'exp_pct', 'n_ev', 'e1983', 'e1998', 'e2017', 'e2023_24', 'dmg_cuenca'];
const HEAD = ['Ubigeo', 'Departamento', 'Provincia', 'Distrito', 'Cuenca', 'Nivel', 'Grupo', 'Score', 'Exp.%', 'N.eventos', 'Ev.1983', 'Ev.1998', 'Ev.2017', 'Ev.2023-24', 'Damnif.cuenca'];
const aoaOf = arr => [HEAD, ...arr.map(r => COLS.map(k => r[k]))];
const W = [8, 16, 22, 26, 26, 7, 9, 8, 7, 9, 8, 8, 8, 10, 13];
const wb = XLSX.utils.book_new();
const addS = (name, arr) => { const ws = XLSX.utils.aoa_to_sheet(aoaOf(arr)); ws['!cols'] = W.map(w => ({ wch: w })); ws['!autofilter'] = { ref: 'A1:O1' }; XLSX.utils.book_append_sheet(wb, ws, name); };
// resumen
const byN = {}, byG = {}; recs.forEach(r => { byN[r.nivel] = (byN[r.nivel] || 0) + 1; byG[r.grupo] = (byG[r.grupo] || 0) + 1; });
const res = [['DISTRITOS AFECTADOS POR FEN (Pacifico, R1-R5) — excluye R0 no-Pacifico'], [],
  ['Total distritos FEN', recs.length], [],
  ['Por nivel'], ...['R1', 'R2', 'R3', 'R4', 'R5'].map(n => [n, byN[n] || 0]), [],
  ['Por grupo consolidado'], ['G3 Alto (R4+R5)', byG['G3 Alto'] || 0], ['G2 Medio (R2+R3)', byG['G2 Medio'] || 0], ['G1 Bajo (R1)', byG['G1 Bajo'] || 0]];
const rs = XLSX.utils.aoa_to_sheet(res); rs['!cols'] = [{ wch: 42 }, { wch: 10 }]; XLSX.utils.book_append_sheet(wb, rs, 'Resumen');
addS('Todos_FEN', recs);
addS('G3_Alto', recs.filter(r => r.grupo === 'G3 Alto'));
addS('G2_Medio', recs.filter(r => r.grupo === 'G2 Medio'));
addS('G1_Bajo', recs.filter(r => r.grupo === 'G1 Bajo'));
const f = path.join(OUT, 'Distritos_por_grupo_FEN.xlsx');
let out = f; try { XLSX.writeFile(wb, f); } catch (e) { if (e.code === 'EBUSY' || e.code === 'EPERM') { out = f.replace(/\.xlsx$/, '_NEW.xlsx'); XLSX.writeFile(wb, out); } else throw e; }
console.log('ESCRITO: ' + out);
console.log('distritos FEN: ' + recs.length + ' | por grupo: ' + JSON.stringify(byG) + ' | por nivel: ' + JSON.stringify(byN));
