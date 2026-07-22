'use strict';
// Auditoria distrito-por-distrito de los distritos FEN (Pacifico, R1-R5) contra los criterios
// de los validadores: patron de eventos, vertiente, etiqueta de cuenca, severidad sin match,
// exp~0 en nivel alto, borde de corte, datos vacios. Genera Auditoria_distrital_FEN.xlsx. READ-ONLY.
const XLSX = require('C:/Users/CARLOS/elnino_ibk/02_pipeline/node_modules/xlsx');
const fs = require('fs'); const path = require('path');
const B = path.join(__dirname, '..');
const OUT = path.join(__dirname, 'resultados'); fs.mkdirSync(OUT, { recursive: true });
const rd = f => { const L = fs.readFileSync(f, 'utf8').trim().split(/\r?\n/); const H = L[0].replace(/^﻿/, '').split(','); const ix = {}; H.forEach((h, i) => ix[h] = i); return { ix, rows: L.slice(1).map(l => l.match(/(?:^|,)("(?:[^"]|"")*"|[^,]*)/g).map(s => s.replace(/^,/, '').replace(/^"|"$/g, ''))) }; }
const pad = u => String(u || '').replace(/\D/g, '').padStart(6, '0');
// 1) grado
const g = rd(B + '/02_pipeline/out/grado_fen_v3.csv');
// 2) distrito_cuenca -> vertiente
const dc = rd(B + '/01_inputs/geo/distrito_cuenca.csv'); const VERT = {};
dc.rows.forEach(c => VERT[pad(c[dc.ix.ubigeo])] = c[dc.ix.vertiente]);
// 3) escenario_severo -> set de claves de cuenca con severidad historica
const sc = rd(B + '/02_pipeline/intermedios/escenario_severo_cuenca.csv'); const SEVKEY = new Set();
sc.rows.forEach(c => SEVKEY.add(c[sc.ix.cuenca]));
const SUR = new Set(['HUANCAVELICA', 'AYACUCHO', 'APURIMAC', 'TACNA', 'MOQUEGUA', 'PUNO', 'AREQUIPA', 'CUSCO']);
const cuts = [0.66, 1.40, 2.20, 3.05];
const recs = g.rows.filter(c => +c[g.ix.pacifico] === 1).map(c => {
  const u = pad(c[g.ix.ubigeo]), dep = c[g.ix.departamento], prov = c[g.ix.provincia], dist = c[g.ix.distrito];
  const cuenca = c[g.ix.cuenca], r = c[g.ix.R_nivel], score = +c[g.ix.score] || 0, exp = +c[g.ix.pct_expuesto] || 0;
  const a83 = +c[g.ix.a1983] || 0, a98 = +c[g.ix.a1998] || 0, a17 = +c[g.ix.a2017] || 0, a23 = +c[g.ix.a2324] || 0;
  const n = +c[g.ix.n_eventos] || 0, dmgC = +c[g.ix.dmg_cuenca] || 0, dmgP = +c[g.ix.dmg17_propio] || 0;
  const persistente = (a83 || a98) ? 1 : 0;
  const patron = persistente ? 'persistente(83/98)' : ((a17 || a23) ? 'reciente_solo' : 'sin_eventos');
  const vert = VERT[u] || '?';
  const sevC = Math.min(dmgC / 121041, 1), sevP = Math.min(dmgP / 3052, 1);
  const sevDriver = sevC >= sevP ? 'cuenca' : 'propio2017';
  const flags = [];
  if (patron === 'reciente_solo' && SUR.has((dep || '').toUpperCase())) flags.push('SUR_RECIENTE_SOLO');     // contaminacion mecanismo
  if (!/^Cuenca /.test(cuenca)) flags.push('CUENCA_LABEL');                                                   // Pfafstetter/sin prefijo
  if (!SEVKEY.has(cuenca)) flags.push('SEV_SIN_MATCH');                                                       // severidad historica no matchea
  if ((r === 'R4' || r === 'R5') && exp < 5) flags.push('EXP0_ALTO');                                         // recurrencia/sev-driven
  if (cuts.some(k => Math.abs(score - k) <= 0.05)) flags.push('BORDE_CORTE');                                 // pegado a un corte
  if (!prov || !dist) flags.push('DATOS_VACIOS');
  if ((vert && !/Pac/i.test(vert))) flags.push('VERTIENTE_NO_PAC');                                           // FEN pero no Pacifico (raro)
  return { u, dep, prov, dist, cuenca, vert, r, score: +score.toFixed(3), exp: +exp.toFixed(1), n, a83, a98, a17, a23, patron, dmgC: Math.round(dmgC), dmgP: Math.round(dmgP), sevDriver, flags: flags.join(' '), nflags: flags.length };
});
// orden: mas flags primero, luego R desc
recs.sort((a, b) => b.nflags - a.nflags || b.r.localeCompare(a.r) || b.score - a.score);
const COLS = ['u', 'dep', 'prov', 'dist', 'cuenca', 'vert', 'r', 'score', 'exp', 'n', 'a83', 'a98', 'a17', 'a23', 'patron', 'dmgC', 'dmgP', 'sevDriver', 'flags'];
const HEAD = ['Ubigeo', 'Departamento', 'Provincia', 'Distrito', 'Cuenca', 'Vertiente', 'Nivel', 'Score', 'Exp%', 'Nev', '1983', '1998', '2017', '2023-24', 'Patron', 'DmgCuenca', 'DmgPropio', 'SevDriver', 'FLAGS'];
const W = [8, 14, 20, 24, 24, 12, 6, 7, 6, 4, 5, 5, 5, 7, 18, 11, 10, 11, 28];
const wb = XLSX.utils.book_new();
const addS = (name, arr, head) => { const ws = XLSX.utils.aoa_to_sheet([head || HEAD, ...arr.map(r => COLS.map(k => r[k]))]); ws['!cols'] = W.map(x => ({ wch: x })); ws['!autofilter'] = { ref: 'A1:S1' }; XLSX.utils.book_append_sheet(wb, ws, name); };
// conteos por flag
const fc = {}; recs.forEach(r => r.flags.split(' ').filter(Boolean).forEach(f => fc[f] = (fc[f] || 0) + 1));
const res = [['AUDITORIA DISTRITAL FEN (Pacifico R1-R5) — ' + recs.length + ' distritos'], [],
  ['Flag', 'n distritos', 'Que significa'],
  ['SUR_RECIENTE_SOLO', fc['SUR_RECIENTE_SOLO'] || 0, 'Sur andino, solo eventos 2017/2023 (mecanismo dudoso vs ENSO) -> contaminacion DiD'],
  ['CUENCA_LABEL', fc['CUENCA_LABEL'] || 0, 'Etiqueta de cuenca sin prefijo "Cuenca " (Pfafstetter/Intercuenca/UH) -> fragmentacion'],
  ['SEV_SIN_MATCH', fc['SEV_SIN_MATCH'] || 0, 'Cuenca no matchea escenario_severo -> severidad historica posible subestimada'],
  ['EXP0_ALTO', fc['EXP0_ALTO'] || 0, 'R4/R5 con exp<5% -> nivel por recurrencia/severidad, no exposicion areal (documentar)'],
  ['BORDE_CORTE', fc['BORDE_CORTE'] || 0, 'Score a +-0.05 de un corte Jenks -> caso frontera (se preguntara en validacion)'],
  ['DATOS_VACIOS', fc['DATOS_VACIOS'] || 0, 'Provincia/Distrito vacios en el CSV (bug de comillas)'],
  ['VERTIENTE_NO_PAC', fc['VERTIENTE_NO_PAC'] || 0, 'Clasificado FEN pero vertiente no-Pacifico (revisar gate)'],
  [], ['Total distritos con >=1 flag', recs.filter(r => r.nflags > 0).length]];
const rs = XLSX.utils.aoa_to_sheet(res); rs['!cols'] = [{ wch: 22 }, { wch: 12 }, { wch: 70 }]; XLSX.utils.book_append_sheet(wb, rs, 'Resumen');
addS('Todos_FEN', recs);
addS('A_revisar', recs.filter(r => r.nflags > 0));
addS('R4_R5', recs.filter(r => r.r === 'R4' || r.r === 'R5'));
let out = path.join(OUT, 'Auditoria_distrital_FEN.xlsx');
try { XLSX.writeFile(wb, out); } catch (e) { if (e.code === 'EBUSY' || e.code === 'EPERM') { out = out.replace(/\.xlsx$/, '_NEW.xlsx'); XLSX.writeFile(wb, out); } else throw e; }
// consola: resumen + casos nombrados por validadores
console.log('ESCRITO:', out, '| FEN:', recs.length, '| con flag:', recs.filter(r => r.nflags > 0).length);
console.log('Conteo flags:', JSON.stringify(fc));
const named = ['CAMANA', 'MAJES', 'SAMUEL PASTOR', 'TAMBO DE MORA', 'PARACAS', 'AYAVI', 'CASTROVIRREYNA', 'TARATA', 'CANDARAVE', 'LA UNION', 'TAMARINDO', 'COLAN', 'PAITA'];
console.log('\nCasos nombrados por validadores:');
recs.filter(r => named.includes((r.dist || '').toUpperCase())).forEach(r => console.log((r.dep + '/' + r.dist).padEnd(34), r.r, 'sc', r.score, 'exp', r.exp, 'n', r.n, '['+r.patron+']', r.cuenca, '->', r.flags || '(sin flag)'));
console.log('\nR4/R5 con patron reciente_solo (sospechosos):');
recs.filter(r => (r.r === 'R4' || r.r === 'R5') && r.patron === 'reciente_solo').forEach(r => console.log((r.dep + '/' + r.dist).padEnd(34), r.r, 'sc', r.score, 'n', r.n, r.cuenca));
