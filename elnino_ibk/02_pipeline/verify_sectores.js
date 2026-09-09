'use strict';
const fs = require('fs');
const B = 'C:/Users/CARLOS/elnino_ibk/02_pipeline/out';
const rd = f => fs.readFileSync(f, 'utf8').replace(/^\uFEFF/, '').trim().split(/\r?\n/);
const parse = l => l.split(',');
const load = f => { const L = rd(f); const H = L[0].split(','); const m = {};
  for (const l of L.slice(1)) { const c = parse(l); const o = {}; H.forEach((h, i) => o[h] = c[i]); m[o.ubigeo] = o; } return m; };

const T = load(B + '/sectores_agua_distrito.csv');       // original (ground truth)
const R = load(B + '/sectores_agua_distrito_REGEN.csv');  // reconstruido

const tk = Object.keys(T), rk = Object.keys(R);
const falta = tk.filter(u => !R[u]);   // en original, no en regen
const sobra = rk.filter(u => !T[u]);   // en regen, no en original
console.log('== COBERTURA ==');
console.log('original:', tk.length, '| regen:', rk.length, '| faltan:', falta.length, '| sobran:', sobra.length);
if (falta.length) console.log('  faltan:', falta.slice(0, 20).join(' '));
if (sobra.length) console.log('  sobran:', sobra.slice(0, 20).join(' '));

const comun = tk.filter(u => R[u]);
// ---- nivel ----
let nivelOk = 0; const nivelBad = [];
for (const u of comun) { if (T[u].nivel === R[u].nivel) nivelOk++; else nivelBad.push(u); }
console.log('\n== NIVEL (S0-S4) ==');
console.log('match exacto:', nivelOk, '/', comun.length, '=', (100 * nivelOk / comun.length).toFixed(2) + '%');

// ---- s_total ----
let sMax = 0, sSum = 0, sLt01 = 0; const sBad = [];
for (const u of comun) {
  const a = +T[u].s_total, b = +R[u].s_total, dd = Math.abs(a - b);
  sSum += dd; if (dd > sMax) sMax = dd; if (dd < 0.01) sLt01++;
  if (dd >= 0.0001) sBad.push([u, a, b, dd]);
}
console.log('\n== s_total ==');
console.log('media |d|:', (sSum / comun.length).toExponential(3), '| max |d|:', sMax.toFixed(6),
  '| filas |d|<0.01:', sLt01, '=', (100 * sLt01 / comun.length).toFixed(2) + '%',
  '| filas |d|>=1e-4:', sBad.length);

// ---- columna por columna: coincidencia exacta de string ----
const cols = ['departamento','provincia','distrito','vertiente','pea_ocupada','pct_agua','pct_expuesto',
  'pct_desacoplado','pct_construccion','pct_informal','canal','flg_pesquero','s_intrinseco','s_demanda','s_total','nivel'];
console.log('\n== MATCH EXACTO POR COLUMNA (string) ==');
const colBad = {};
for (const col of cols) {
  let ok = 0; const bad = [];
  for (const u of comun) { if (String(T[u][col]) === String(R[u][col])) ok++; else if (bad.length < 6) bad.push(u); }
  colBad[col] = bad;
  console.log('  ' + col.padEnd(16), (ok + '/' + comun.length).padStart(11), (100 * ok / comun.length).toFixed(2).padStart(6) + '%',
    bad.length ? '  ej: ' + bad.join(',') : '');
}

// ---- muestra de discrepancias de nivel ----
if (nivelBad.length) {
  console.log('\n== DISCREPANCIAS DE NIVEL (hasta 15) ==');
  for (const u of nivelBad.slice(0, 15))
    console.log('  ', u, T[u].distrito, '| orig', T[u].nivel, 's=' + T[u].s_total, '-> regen', R[u].nivel, 's=' + R[u].s_total);
}
// ---- muestra de discrepancias de s_total ----
if (sBad.length) {
  console.log('\n== DISCREPANCIAS s_total (hasta 15, |d|>=1e-4) ==');
  sBad.sort((a, b) => b[3] - a[3]);
  for (const x of sBad.slice(0, 15)) {
    const u = x[0];
    console.log('  ', u, T[u].distrito.padEnd(22),
      'orig s_int/s_dem/s_tot=', T[u].s_intrinseco, T[u].s_demanda, T[u].s_total,
      '| regen=', R[u].s_intrinseco, R[u].s_demanda, R[u].s_total,
      '| pct_agua o/r=', T[u].pct_agua + '/' + R[u].pct_agua,
      'exp=', T[u].pct_expuesto + '/' + R[u].pct_expuesto,
      'constr=', T[u].pct_construccion + '/' + R[u].pct_construccion,
      'flg=', T[u].flg_pesquero + '/' + R[u].flg_pesquero);
  }
}
