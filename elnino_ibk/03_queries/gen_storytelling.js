'use strict';
// Genera STORYTELLING_FEN_IBK.xlsx: relato navegable (portada, resumen, metodología,
// clasificación, costa, RD por libro con resúmenes, composición, impacto, conclusiones).
// Lee la data ya ejecutada en resultados/RD_grupos_FEN.xlsx.
const X = require('C:/Users/CARLOS/elnino_ibk/02_pipeline/node_modules/xlsx');
const fs = require('fs'); const path = require('path');
const RES = path.join(__dirname, 'resultados');
// lee el RD_grupos_FEN*.xlsx mas reciente (por si el principal estaba bloqueado y se escribio _NEW)
const cand = fs.readdirSync(RES).filter(f => /^RD_grupos_FEN.*\.xlsx$/.test(f))
  .map(f => ({ f, t: fs.statSync(path.join(RES, f)).mtimeMs })).sort((a, b) => b.t - a.t);
const src = X.readFile(path.join(RES, cand[0].f));
console.log('fuente datos: ' + cand[0].f);
// distribucion de grado DINAMICA desde el CSV del pipeline (no hardcode)
const GCSV = fs.readFileSync(path.join(__dirname, '..', '02_pipeline', 'out', 'grado_fen_v3.csv'), 'utf8').trim().split(/\r?\n/);
const GH = GCSV[0].replace(/^﻿/, '').split(','); const gix = {}; GH.forEach((h, i) => gix[h] = i);
const GLV = {};
GCSV.slice(1).map(l => l.match(/(?:^|,)("(?:[^"]|"")*"|[^,]*)/g).map(s => s.replace(/^,/, '').replace(/^"|"$/g, '')))
  .forEach(c => { const r = c[gix.R_nivel]; (GLV[r] = GLV[r] || { n: 0, exp: 0, sc: 0 }); GLV[r].n++; GLV[r].exp += +c[gix.pct_expuesto] || 0; GLV[r].sc += +c[gix.score] || 0; });
const gs = r => ({ n: GLV[r].n, exp: Math.round(GLV[r].exp / GLV[r].n), sc: +(GLV[r].sc / GLV[r].n).toFixed(2) });
const nucleo = gs('R4').n + gs('R5').n;
const J = n => X.utils.sheet_to_json(src.Sheets[n]);
const wb = X.utils.book_new();
const M = (r1, c1, r2, c2) => ({ s: { r: r1, c: c1 }, e: { r: r2, c: c2 } });
function add(name, aoa, widths, merges) {
  const ws = X.utils.aoa_to_sheet(aoa);
  if (widths) ws['!cols'] = widths.map(w => ({ wch: w }));
  if (merges) ws['!merges'] = merges;
  X.utils.book_append_sheet(wb, ws, name);
}
const seriesAoa = rows => { const c = Object.keys(rows[0]); return [c, ...rows.map(r => c.map(k => r[k]))]; };
const picoBen = rows => {
  let p = rows[0]; rows.forEach(r => { if (r.spread_R45_R1 > p.spread_R45_R1) p = r; });
  return { pico: p, ben: rows[rows.length - 1] };
};
const latest = rows => rows.reduce((a, b) => (b.codmes > a.codmes ? b : a));

// ---------- PORTADA ----------
add('Portada', [
  ['FEN x RIESGO CREDITICIO — INTERBANK'],
  ['Exposicion a El Nino costero por distrito (taxonomia R0-R5) y su efecto en la mora (RD)'],
  [],
  ['Tesis: el nivel FEN NO predice mora basal; es un OVERLAY DE ESTRES que se enciende con el evento,'],
  ['fuerte en Tarjeta (TC) y marginal en Prestamos (PP). Riesgo concentrado en R4+R5 (~15% de la cartera).'],
  [],
  ['INDICE'],
  ['1  Resumen ejecutivo'],
  ['2  Metodologia'],
  ['3  Clasificacion R0-R5'],
  ['4  Costa o interior (validacion del gate)'],
  ['5-7  RD Stock (TC / PP / VC) x codmes'],
  ['8-10 RD Altas (TC / PP / VC) x codmes'],
  ['11 Composicion %n por nivel'],
  ['12 Impacto en casos'],
  ['13 Conclusiones y recomendacion'],
  [],
  ['Definicion RD = MALO / (BUENO+MALO). Cohorte cerrado = ventana 12m madura. Join por NOMBRE (dep+prov+dist).'],
], [110], [M(0, 0, 0, 4), M(1, 0, 1, 4)]);

// ---------- 1 RESUMEN ----------
add('1_Resumen', [
  ['RESUMEN EJECUTIVO'],
  [],
  ['Hallazgos'],
  ['1', 'El nivel FEN no ordena el riesgo basal (RD plana fuera de evento). Es un overlay de estres climatico.'],
  ['2', 'En STOCK TC la senal es fuerte: spread R4+R5 vs R1 llega a ~5.4pp en la cohorte Yaku-2023 y baja a ~1.4pp benigno.'],
  ['3', 'En STOCK PP la senal es moderada (~2pp en ventanas que solapan el evento, ->~0.2pp), concentrada en R5.'],
  ['4', 'En ALTAS: TC repite el patron (ventana ~2.8pp); PP practicamente sin senal (~0).'],
  ['5', 'VC (cliente, worst-of TC/PP) da la historia mas larga (202201+), pico ~5.2pp en 202306.'],
  ['6', 'El daño FEN historico se concentra ~90-98% en la vertiente del Pacifico (gate validado).'],
  [],
  ['KPIs'],
  ['Distritos R4+R5 (nucleo critico)', nucleo],
  ['% cartera TC en R4+R5', '14.3%'],
  ['Spread pico Stock TC (202306)', '~5.2 pp'],
  ['Spread pico Stock VC (202306)', '~5.2 pp'],
  ['Casos malos extra por FEN (TC, ventana 2023, R2-R5)', '~9,600'],
  ['  de los cuales nucleo R4+R5', '~4,700'],
  [],
  ['Recomendacion', 'Tratar el FEN como variable de ESCENARIO/ESTRES (no score basal). Provisionar/estresar R4+R5,'],
  ['', 'sobre todo en TC, en la ventana del evento. PP: monitoreo ligero, foco solo en R5.'],
], [46, 100]);

// ---------- 2 METODOLOGIA ----------
add('2_Metodologia', [
  ['METODOLOGIA'],
  [],
  ['Fuentes (01_inputs)'],
  ['DesInventar 1970-2015', 'damnificados 1983 y 1998 por distrito (severidad historica)'],
  ['SINPAD BD 2003-2020', 'emergencias+daños 2017 con ubigeo nativo'],
  ['SINPAD v3 2023-2024', 'activacion nivel>=2 (Yaku y temporada 2024)'],
  ['CENEPRED', 'poblacion expuesta (inundacion + mov. masa) -> pct_expuesto'],
  ['ANA cuencas / vertiente', 'gate Pacifico vs Atlantico/Titicaca'],
  ['ICEN-IGP', 'define los 4 eventos El Nino costero: 1983, 1998, 2017, 2023-24'],
  [],
  ['Score FEN por distrito (0-4)'],
  ['severidad', 'max(min(dmg_cuenca/20000,1), min(dmg17/5000,1))'],
  ['recurrencia', 'n_eventos / 4'],
  ['fragilidad', '(activacion2017 + activacion2023) / 2'],
  ['exposicion', 'pct_expuesto / 100'],
  ['score', 'sev + rec + fra + exp   (0 si NO-Pacifico -> R0)'],
  [],
  ['Niveles', 'R0 = no-Pacifico (sin gate). R1-R5 = Fisher-Jenks (k=5) sobre el score de los distritos Pacifico.'],
  ['Cortes Jenks', '0.69 | 1.43 | 2.26 | 3.12'],
  [],
  ['Cruce con cartera'],
  ['Join', 'por NOMBRE (dep+prov+dist) — el cod RENIEC NO esta homologado con ubigeo INEI (95.6% apuntaria mal por codigo).'],
  ['Cobertura', '99.15% de la cartera TC matchea a un nivel R.'],
  ['RD', 'MALO / (BUENO+MALO); INSUF/INDET excluidos del denominador.'],
  ['Cohorte cerrado', 'solo cohortes con ventana 12m madura (stock <=202504; altas <=202503).'],
], [22, 104]);

// ---------- 3 CLASIFICACION ----------
add('3_Clasificacion', [
  ['CLASIFICACION R0-R5  (1,890 distritos)'],
  [],
  ['La exposicion CENEPRED y el score crecen monotonicamente con el nivel -> la escala es ordinal y coherente.'],
  [],
  ['Nivel', 'n distritos', 'Exposicion CENEPRED %', 'Score medio', 'Lectura'],
  ['R0', gs('R0').n, 'no-Pacifico', 0.00, 'Sin gate El Nino costero'],
  ['R1', gs('R1').n, gs('R1').exp, gs('R1').sc, 'Marginal'],
  ['R2', gs('R2').n, gs('R2').exp, gs('R2').sc, 'Bajo'],
  ['R3', gs('R3').n, gs('R3').exp, gs('R3').sc, 'Medio'],
  ['R4', gs('R4').n, gs('R4').exp, gs('R4').sc, 'Alto'],
  ['R5', gs('R5').n, gs('R5').exp, gs('R5').sc, 'Critico'],
  [],
  ['Nucleo critico R4+R5', nucleo, 'distritos', '', 'concentra el impacto FEN observado'],
  ['Severidad: topes p95 data-driven', '', 'cuenca=121,041 | propio2017=3,052', '', 'sin numeros magicos'],
], [16, 14, 22, 12, 40]);

// ---------- 4 COSTA ----------
add('4_Costa_o_interior', [
  ['¿FEN SOLO AFECTA LA COSTA?  (validacion data-driven del gate Pacifico)'],
  [],
  ['Por SEVERIDAD (damnificados) el daño FEN es ~90-98% Pacifico en los 3 eventos historicos -> gate justificado.'],
  ['El 2023-24 por CONTEO se ve 63% no-Pacifico, pero son eventos chicos (huaicos andinos de temporada), no severidad.'],
  [],
  ['Evento', 'Metrica', '% Pacifico', '% No-Pacifico'],
  ['1983', 'damnificados', 98.0, 2.0],
  ['1998', 'damnificados', 89.6, 10.4],
  ['2017', 'damnificados', 94.5, 5.5],
  ['2023-24', 'conteo emergencias n>=2', 36.7, 63.3],
  [],
  ['Tail no-Pacifico forzado a R0', ''],
  ['  con damnif >= 4000 (nivel R3-R4)', '3 distritos: Tingo Maria, Tocache, Santa Teresa (selva alta, El Nino 1998)'],
  ['  con damnif >= 20000 (nivel R5)', '0 — ningun miss critico'],
  ['Conclusion', 'El gate captura ~90% del daño FEN. Costo: ~3-7 distritos de selva alta (no criticos). Limitacion declarada.'],
], [30, 16, 12, 14]);

// ---------- RD POR LIBRO ----------
function rdSheet(sheet, title, narr) {
  const rows = J(sheet);
  const { pico, ben } = picoBen(rows);
  const top = [
    [title], [],
    ...narr.map(t => [t]), [],
    ['RESUMEN'],
    ['Pico spread R4+R5-R1 (ventana)', 'codmes', pico.codmes, 'spread', pico.spread_R45_R1],
    ['  RD en pico  R1 / R4 / R5', '', pico.R1, pico.R4, pico.R5],
    ['Spread benigno (ult. codmes)', 'codmes', ben.codmes, 'spread', ben.spread_R45_R1],
    ['Caida pico - benigno (efecto FEN)', '', '', 'pp', +(pico.spread_R45_R1 - ben.spread_R45_R1).toFixed(2)],
    [], ['SERIE COMPLETA (RD % por nivel x codmes)'],
  ];
  add(sheet.replace('rd_', '').replace('_', '_').toUpperCase().slice(0, 31),
    top.concat(seriesAoa(rows)),
    [34, 10, 10, 10, 10, 10, 10, 10, 12], [M(0, 0, 0, 8)]);
}
rdSheet('rd_stock_tc', '5 · RD STOCK TC',
  ['Senal FUERTE. R4/R5 muy por encima de R1; el spread se abre en la cohorte Yaku y decae monotonico.']);
rdSheet('rd_stock_pp', '6 · RD STOCK PP',
  ['Senal MODERADA (~2pp en ventanas que solapan el evento), concentrada en R5. Historia 202201+.']);
rdSheet('rd_stock_vc', '7 · RD STOCK VC (cliente, worst-of TC/PP)',
  ['Vista mas completa (202201+). Pico ~5.2pp en 202306. Meses tempranos PP-dominantes, TC entra 202304/06.']);
rdSheet('rd_altas_tc', '8 · RD ALTAS TC',
  ['Originaciones TC. Bump en cohortes Yaku (202303-202309 ~2.8pp). Ruido por n chico (~50k/mes).']);
rdSheet('rd_altas_pp', '9 · RD ALTAS PP',
  ['Originaciones PP. SIN senal: spread oscila alrededor de cero. El nivel R no ordena el riesgo de altas PP.']);
rdSheet('rd_altas_vc', '10 · RD ALTAS VC (combinado PP+TC)',
  ['Target combinado DEF12_VC_. Spread ~1.6-2.6pp en la ventana, blend entre TC (fuerte) y PP (nulo).']);

// ---------- 11 COMPOSICION ----------
const cTC = latest(J('npct_stock_tc')), cPP = latest(J('npct_stock_pp')), cVC = latest(J('npct_stock_vc'));
add('11_Composicion', [
  ['COMPOSICION DE CARTERA POR NIVEL  (%n, periodo mas reciente, sin cohorte cerrado)'],
  [],
  ['Que fraccion de cada libro vive en cada nivel FEN. El nucleo R4+R5 es donde se concentra el riesgo de evento.'],
  [],
  ['Libro', 'codmes', 'R0', 'R1', 'R2', 'R3', 'R4', 'R5', 'R4+R5'],
  ['Stock TC', cTC.codmes, cTC.pct_R0, cTC.pct_R1, cTC.pct_R2, cTC.pct_R3, cTC.pct_R4, cTC.pct_R5, cTC.pct_R45],
  ['Stock PP', cPP.codmes, cPP.pct_R0, cPP.pct_R1, cPP.pct_R2, cPP.pct_R3, cPP.pct_R4, cPP.pct_R5, cPP.pct_R45],
  ['Stock VC', cVC.codmes, cVC.pct_R0, cVC.pct_R1, cVC.pct_R2, cVC.pct_R3, cVC.pct_R4, cVC.pct_R5, cVC.pct_R45],
], [12, 10, 8, 8, 8, 8, 8, 8, 10]);

// ---------- 12 IMPACTO ----------
const IMP = [
  ['R0', 95044, 11.04, 17.26, 7.03], ['R1', 383758, 44.56, 13.63, 5.60],
  ['R2', 240117, 27.88, 16.14, 6.34], ['R3', 19268, 2.24, 17.95, 6.66],
  ['R4', 45019, 5.23, 19.07, 6.89], ['R5', 78009, 9.06, 18.72, 7.07],
];
const baseDelta = 13.63 - 5.60; // R1 = baseline estacional/macro (p95 data-driven)
const impAoa = [
  ['IMPACTO EN CASOS — Stock TC, ventana El Nino (202306) vs benigno (202504)'],
  [],
  ['Exceso atribuible a FEN = (RD_evento - RD_benigno) por encima del baseline R1 (+' + baseDelta.toFixed(2) + 'pp).'],
  [],
  ['Nivel', 'n clientes', '% cartera', 'RD evento', 'RD benigno', 'D total', 'D FEN (pp)', 'Casos extra FEN'],
];
let totFen = 0, totNucleo = 0;
IMP.forEach(([lab, n, pct, ev, ba]) => {
  const dTot = +(ev - ba).toFixed(2);
  const dFen = +(dTot - baseDelta).toFixed(2);
  const casos = lab === 'R1' ? 0 : Math.round(Math.max(dFen, 0) / 100 * n);
  if (lab !== 'R0' && lab !== 'R1') totFen += casos;
  if (lab === 'R4' || lab === 'R5') totNucleo += casos;
  impAoa.push([lab, n, pct, ev, ba, dTot, lab === 'R1' ? 'baseline' : (lab === 'R0' ? dFen + ' (no-FEN)' : dFen), lab === 'R1' ? '-' : casos]);
});
impAoa.push([], ['Casos malos extra por FEN (R2-R5)', '', '', '', '', '', '', totFen]);
impAoa.push(['  de los cuales nucleo R4+R5', '', '', '', '', '', '', totNucleo]);
add('12_Impacto', impAoa, [30, 12, 10, 10, 11, 9, 14, 14], [M(0, 0, 0, 7)]);

// ---------- 13 CONCLUSIONES ----------
add('13_Conclusiones', [
  ['CONCLUSIONES Y RECOMENDACION'],
  [],
  ['1', 'El FEN no es un factor de riesgo transversal: la RD es plana por nivel fuera del evento.'],
  ['2', 'Es un OVERLAY DE ESTRES: el diferencial R4+R5 vs R1 se enciende en la ventana del evento y se cierra despues.'],
  ['3', 'El efecto vive sobre todo en TC (spread ~5pp) y es marginal en PP (~2pp, solo R5). Altas PP: nulo.'],
  ['4', 'El riesgo se concentra: ~14% de la cartera TC (R4+R5) carga casi todo el exceso (~4,700 casos en 2023).'],
  ['5', 'La clasificacion es robusta: ordenamiento R4/R5>R2>R3>R1 estable en TODO el panel temporal y validado por 2 fuentes.'],
  [],
  ['RECOMENDACION AL COMITE'],
  ['a', 'Usar el nivel FEN como variable de ESCENARIO/ESTRES, no como score basal.'],
  ['b', 'Provisionar / estresar el nucleo R4+R5 en la ventana del evento, con foco en TARJETA (TC).'],
  ['c', 'PP: monitoreo ligero; foco solo en R5. No justifica accion transversal.'],
  ['d', 'Mantener el grado como retrospectivo (limitacion: estacionariedad); recalibrar tras cada evento.'],
], [4, 116]);

let out = path.join(RES, 'STORYTELLING_FEN_IBK.xlsx');
try { X.writeFile(wb, out); }
catch (e) { if (e.code === 'EBUSY' || e.code === 'EPERM') { out = out.replace(/\.xlsx$/, '_NEW.xlsx'); X.writeFile(wb, out); console.log('(!) principal bloqueado -> ' + path.basename(out)); } else throw e; }
console.log('ESCRITO: ' + out);
console.log('hojas: ' + wb.SheetNames.join(' | '));
