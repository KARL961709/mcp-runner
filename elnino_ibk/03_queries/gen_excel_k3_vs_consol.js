'use strict';
// Compara dos formas de llegar a 3 grupos del score FEN (solo score, sin riesgo):
//   A) CONSOLIDADO: Jenks k=5 (R1..R5) y luego agrupar R1=Bajo, R2+R3=Medio, R4+R5=Alto.
//   B) JENKS DIRECTO k=3 sobre el score.
// Genera Comparacion_k5group_vs_k3.xlsx. NO modifica nada existente.
const XLSX = require('C:/Users/CARLOS/elnino_ibk/02_pipeline/node_modules/xlsx');
const fs = require('fs'); const path = require('path');
const CSV = path.join(__dirname, '..', '02_pipeline', 'out', 'grado_fen_v3.csv');
const OUT = path.join(__dirname, 'resultados'); fs.mkdirSync(OUT, { recursive: true });
const L = fs.readFileSync(CSV, 'utf8').trim().split(/\r?\n/);
const H = L[0].replace(/^﻿/, '').split(','); const ix = {}; H.forEach((h, i) => ix[h] = i);
const P = l => l.match(/(?:^|,)("(?:[^"]|"")*"|[^,]*)/g).map(s => s.replace(/^,/, '').replace(/^"|"$/g, ''));
const all = L.slice(1).map(P);
const R = all.filter(c => +c[ix.pacifico] === 1).map(c => ({
  ub: c[ix.ubigeo], dep: c[ix.departamento], prov: c[ix.provincia], dist: c[ix.distrito],
  s: +c[ix.score], r: c[ix.R_nivel]
}));
function jenks(a, k) { a = a.slice().sort((x, y) => x - y); const n = a.length; const pre = [0], pr2 = [0]; for (let i = 0; i < n; i++) { pre.push(pre[i] + a[i]); pr2.push(pr2[i] + a[i] * a[i]); } const cost = (i, j) => { const s = pre[j + 1] - pre[i], s2 = pr2[j + 1] - pr2[i], c = j - i + 1; return s2 - s * s / c; }; const dp = Array.from({ length: n + 1 }, () => Array(k + 1).fill(1e18)), br = Array.from({ length: n + 1 }, () => Array(k + 1).fill(0)); dp[0][0] = 0; for (let i = 1; i <= n; i++) for (let j = 1; j <= Math.min(k, i); j++) for (let p = j - 1; p < i; p++) { const v = dp[p][j - 1] + cost(p, i - 1); if (v < dp[i][j]) { dp[i][j] = v; br[i][j] = p; } } const idx = []; let i = n, j = k; while (j > 0) { idx.unshift(br[i][j]); i = br[i][j]; j--; } return idx.slice(1).map(p => a[p]); }
const c3 = jenks(R.map(d => d.s), 3);
const G = ['', 'Bajo', 'Medio', 'Alto'];
const buck3 = s => { let r = 1; for (let i = 0; i < c3.length; i++) if (s >= c3[i]) r = i + 2; return r; };
const cons = r => (r === 'R1' ? 1 : (r === 'R2' || r === 'R3' ? 2 : 3));
R.forEach(d => { d.j3 = buck3(d.s); d.cn = cons(d.r); d.coincide = d.j3 === d.cn ? 'SI' : 'NO'; });
const sz = f => [1, 2, 3].map(g => R.filter(d => f(d) === g).length);
const szC = sz(d => d.cn), szJ = sz(d => d.j3);
const conf = [1, 2, 3].map(cn => [1, 2, 3].map(j3 => R.filter(d => d.cn === cn && d.j3 === j3).length));
const agree = R.filter(d => d.coincide === 'SI').length;
const wb = XLSX.utils.book_new();
const addS = (name, aoa, w) => { const ws = XLSX.utils.aoa_to_sheet(aoa); if (w) ws['!cols'] = w.map(x => ({ wch: x })); XLSX.utils.book_append_sheet(wb, ws, name); };
// Resumen
addS('Resumen', [
  ['COMPARACION: agrupar a 3 — Consolidado (5->3) vs Jenks directo k=3   (solo score, sin riesgo)'],
  [],
  ['Metodo', 'Corte Bajo/Medio', 'Corte Medio/Alto', 'n Bajo', 'n Medio', 'n Alto'],
  ['A) Consolidado (Jenks k=5 -> agrupar)', 0.66, 2.20, szC[0], szC[1], szC[2]],
  ['B) Jenks directo k=3', +c3[0].toFixed(3), +c3[1].toFixed(3), szJ[0], szJ[1], szJ[2]],
  [],
  ['Coincidencia', agree + ' / ' + R.length + ' = ' + (100 * agree / R.length).toFixed(1) + '%', '', 'Difieren:', R.length - agree],
  [],
  ['Matriz de confusion (fila = Consolidado, col = Jenks directo k=3)'],
  ['', 'J3-Bajo', 'J3-Medio', 'J3-Alto', 'Total Consol'],
  ['Cons-Bajo', conf[0][0], conf[0][1], conf[0][2], szC[0]],
  ['Cons-Medio', conf[1][0], conf[1][1], conf[1][2], szC[1]],
  ['Cons-Alto', conf[2][0], conf[2][1], conf[2][2], szC[2]],
  ['Total Jenks3', szJ[0], szJ[1], szJ[2], R.length],
  [],
  ['Lectura'],
  ['Jenks NO es jerarquico: los cortes optimos de k=5 no son un refinamiento de los de k=3.'],
  ['Por eso agrupar-desde-5 difiere de cortar-a-3 directo en ~25% de distritos.'],
  ['Diferencia principal: el corte Bajo/Medio (0.66 vs 1.25). El directo-3 mete a Bajo la mitad baja de R2 (164 distritos).'],
  ['Tambien 29 distritos Alto del consolidado (score 2.20-2.39) caen a Medio en el directo-3.'],
  ['Ninguno es "el correcto": optimizan objetivos distintos (5 clases vs 3 clases).'],
], [40, 16, 16, 10, 10, 12]);
// Comparacion por distrito
const HEAD = ['Ubigeo', 'Departamento', 'Provincia', 'Distrito', 'Score', 'R_nivel(k5)', 'Grupo_Consolidado', 'Grupo_Jenks3', 'Coincide'];
const rowsC = R.slice().sort((a, b) => b.s - a.s).map(d => [d.ub, d.dep, d.prov, d.dist, +d.s.toFixed(3), d.r, G[d.cn], G[d.j3], d.coincide]);
const W = [8, 16, 22, 26, 8, 11, 18, 13, 9];
const ws1 = XLSX.utils.aoa_to_sheet([HEAD, ...rowsC]); ws1['!cols'] = W.map(x => ({ wch: x })); ws1['!autofilter'] = { ref: 'A1:I1' };
XLSX.utils.book_append_sheet(wb, ws1, 'Comparacion');
const dif = rowsC.filter(r => r[8] === 'NO');
const ws2 = XLSX.utils.aoa_to_sheet([HEAD, ...dif]); ws2['!cols'] = W.map(x => ({ wch: x })); ws2['!autofilter'] = { ref: 'A1:I1' };
XLSX.utils.book_append_sheet(wb, ws2, 'Difieren_' + dif.length);
let out = path.join(OUT, 'Comparacion_k5group_vs_k3.xlsx');
try { XLSX.writeFile(wb, out); } catch (e) { if (e.code === 'EBUSY' || e.code === 'EPERM') { out = out.replace(/\.xlsx$/, '_NEW.xlsx'); XLSX.writeFile(wb, out); } else throw e; }
console.log('ESCRITO: ' + out);
console.log('cortes Jenks3:', c3.map(x => x.toFixed(3)), '| coincidencia:', (100 * agree / R.length).toFixed(1) + '%', '| difieren:', R.length - agree);
