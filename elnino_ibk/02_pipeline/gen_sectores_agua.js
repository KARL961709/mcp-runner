'use strict';
// GEN_SECTORES_AGUA — reconstruye el "score indirecto s" distrital (dependencia del ingreso al
// agua/clima, tercer eje del FEN) desde las FUENTES, sin depender de ningun output intermedio.
//
// CADENA (todo aqui adentro, auto-contenido):
//   1) UNIVERSO + vertiente ........ out/fen_v6.csv (maestro distrital, 1891 distritos)
//   2) EMPLEO por rama ............. 01_inputs/censo_actividad/pea_rama_distrito.csv (Censo 2017,
//      las 21 ramas de PEA ocupada). Cruce por nombre dep+prov+dist (norm + ALIAS) igual que
//      gen_perfil_hidrico.js; distritos post-2017 -> imputados por mediana provincial.
//   3) AGRUPACION 21 ramas -> 6 perfiles A..F (tabla fija, rama por rama) -> pct_A..pct_F (1 dp).
//   4) BISTURI PESCA .............. 01_inputs/cenec/cenec2022_distrito_ciiu.csv (CIIU 0311/0321,
//      pesca/acuicultura MARINA). flg_pesquero = (personal_pesca >= 10 Y vertiente Pacifico).
//   5) COLUMNAS DEL SCORE:
//        pct_agua       = pct_A                         (agro + pesca, "vive del agua")
//        pct_expuesto   = pct_B + pct_C                 (manufactura/comercio/aloja + transporte)
//        pct_desacoplado= pct_D                         (peso 0)
//        pct_construccion=pct_E                         (contraciclico)
//        pct_informal   = pct_F                         (informal)
//        canal          = MAR si flg_pesquero, si no TIERRA
//        s_intrinseco   = (flg_pesquero?1.5:1.2)*pct_agua/100  - 0.4*pct_construccion/100
//        s_demanda      = 0.5 * pct_agua/100 * (pct_expuesto + pct_informal)/100
//        s_total        = s_intrinseco + s_demanda
//        nivel          = cortes fijos equal-interval de 0.20 sobre s_total (S0..S4)
//      (los pesos +1.5/+1.2/-0.4 y coef 0.5 son DECLARADOS, de SECTORES_ECONOMICOS_FEN.md /
//       PROPUESTA_SCORE_INDIRECTO_DISTRITAL.md; s se calcula sobre los pct redondeados a 1 dp,
//       que es como quedaron congelados en el perfil.)
//
// Salida: out/sectores_agua_distrito_REGEN.csv  (NO sobreescribe el original).
const fs = require('fs');
const B = 'C:/Users/CARLOS/elnino_ibk';

// ---------------------------------------------------------------- 6 perfiles y las 21 ramas
const RAMA = {
  'Agricultura, ganadería, silvicultura y pesca': 'A',
  'Explotación de minas y canteras': 'D',
  'Industrias manufactureras': 'B',
  'Suministro de electricidad, gas, vapor y aire acondicionado': 'D',
  'Suministro de agua; evacua. de aguas residuales, gest. de desechos y descont.': 'D',
  'Construcción': 'E',
  'Comerc., reparación de veh. autom. y motoc.': 'B',
  'Transporte y almacenamiento': 'C',
  'Actividades de alojamiento y de servicio de comidas': 'B',
  'Información y comunicaciones': 'D',
  'Actividades financieras y de seguros': 'D',
  'Actividades inmobiliarias': 'D',
  'Actividades profesionales, científicas y técnicas': 'D',
  'Actividades de servicios administrativos y de apoyo': 'D',
  'Adm. pública y defensa; planes de seguridad social de afiliación obligatoria': 'D',
  'Enseñanza': 'D',
  'Actividades de atención de la salud humana y de asistencia social': 'D',
  'Actividades artísticas, de entretenimiento y recreativas': 'D',
  'Otras actividades de servicios': 'F',
  'Act. de los hogares como empleadores; act. no diferenciadas de los hogares como productores de bienes y servicios para uso propio': 'F',
  'Actividades de organizaciones y órganos extraterritoriales': 'D'
};
const LETRAS = ['A', 'B', 'C', 'D', 'E', 'F'];

// ---------------------------------------------------------------- censo 2017 (empleo por rama)
const CL = fs.readFileSync(B + '/01_inputs/censo_actividad/pea_rama_distrito.csv', 'utf8')
  .replace(/^\uFEFF/, '').trim().split(/\r?\n/).slice(1);
const censo = {}; const vistas = new Set(), huerfanas = new Set();
for (const l of CL) {
  const m = l.match(/^([^,]+),"([^"]*)","([^"]*)","([^"]*)",(\d+)$/); if (!m) continue;
  vistas.add(m[4]);
  if (!RAMA[m[4]]) { huerfanas.add(m[4]); continue; }
  const k = m[1] + '|' + m[2] + '|' + m[3];
  (censo[k] = censo[k] || {})[m[4]] = (censo[k][m[4]] || 0) + +m[5];
}
if (huerfanas.size) { console.log('!! RAMAS SIN PERFIL:'); huerfanas.forEach(r => console.log('  ', r)); process.exitCode = 1; }
const RAMAS = Object.keys(RAMA).filter(r => vistas.has(r));

// ---------------------------------------------------------------- cruce nombre censo <-> maestro
const norm = s => String(s).toUpperCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '')
  .replace(/[^A-Z0-9 ]/g, '').trim().replace(/^DE /, '').replace(/ /g, '');
const ALIAS = {
  '10|HUANUCO|QUISQUI':            'QUISQUI (KICHKI)',
  '10|LEONCIOPRADO|DANIELALOMIASROBLES': 'DANIEL ALOMIA ROBLES',
  '11|NASCA|NAZCA':                'NASCA',
  '12|CHUPACA|SANJUANDEYSCOS':     'SAN JUAN DE ISCOS',
  '15|LIMA|MAGDALENAVIEJA':        'PUEBLO LIBRE',
  '15|HUAROCHIRI|LARAOS':          'SAN PEDRO DE LARAOS',
  '02|HUARAZ|PAMPAS':              'PAMPAS GRANDE'
};
const idx = {}, porNombre = {};
for (const k in censo) {
  const [dc, pr, di] = k.split('|'); const d = dc.replace(/[AB]$/, '');
  idx[d + '|' + norm(pr) + '|' + norm(di)] = censo[k];
  (porNombre[d + '|' + norm(di)] = porNombre[d + '|' + norm(di)] || []).push(censo[k]);
}
const buscar = (dep, prov, dist) => {
  const ali = ALIAS[dep + '|' + norm(prov) + '|' + norm(dist)];
  if (ali && idx[dep + '|' + norm(prov) + '|' + norm(ali)]) return idx[dep + '|' + norm(prov) + '|' + norm(ali)];
  if (idx[dep + '|' + norm(prov) + '|' + norm(dist)]) return idx[dep + '|' + norm(prov) + '|' + norm(dist)];
  const c = porNombre[dep + '|' + norm(dist)];
  return (c && c.length === 1) ? c[0] : null;
};

// ---------------------------------------------------------------- pesca marina desde el CENEC
const CE = fs.readFileSync(B + '/01_inputs/cenec/cenec2022_distrito_ciiu.csv', 'utf8').trim().split(/\r?\n/).slice(1);
const pescaPer = {};
for (const l of CE) {
  const m = l.match(/^(\d+),(\d+),(\d+),(\d+),"(.*)"$/); if (!m) continue;
  if (m[2] === '0311' || m[2] === '0321') pescaPer[m[1]] = (pescaPer[m[1]] || 0) + (+m[4]);
}

// ---------------------------------------------------------------- maestro distrital (universo)
const FL = fs.readFileSync(B + '/02_pipeline/out/fen_v6.csv', 'utf8').replace(/^\uFEFF/, '').trim().split(/\r?\n/);
const H = FL[0].split(','); const ix = {}; H.forEach((h, i) => ix[h] = i);
const parse = l => l.match(/(?:^|,)("(?:[^"]|"")*"|[^,]*)/g).map(s => s.replace(/^,/, '').replace(/^"|"$/g, ''));

const filas = [];
for (const l of FL.slice(1)) {
  const c = parse(l);
  const d = { ub: c[ix.ubigeo], dep: c[ix.departamento], prov: c[ix.provincia], dist: c[ix.distrito], vert: c[ix.vertiente] };
  filas.push({ d, cc: buscar(d.ub.slice(0, 2), d.prov, d.dist) });
}
// imputacion por mediana provincial (distritos creados despues del censo 2017)
const porProv = {};
filas.forEach(f => { if (f.cc) (porProv[f.d.ub.slice(0, 4)] = porProv[f.d.ub.slice(0, 4)] || []).push(f.cc); });
const medRama = lista => {
  if (!lista || !lista.length) return null; const o = {};
  RAMAS.forEach(r => { const v = lista.map(c => (c[r] || 0) / Object.values(c).reduce((a, b) => a + b, 0)).sort((a, b) => a - b); o[r] = v[Math.floor(v.length / 2)]; });
  const t = Object.values(o).reduce((a, b) => a + b, 0); RAMAS.forEach(r => o[r] /= t); return o;
};

// ---------------------------------------------------------------- salida
const nivelDe = v => v <= 0.20 ? 'S0' : v <= 0.40 ? 'S1' : v <= 0.60 ? 'S2' : v <= 0.80 ? 'S3' : 'S4';
const cab = ['ubigeo', 'departamento', 'provincia', 'distrito', 'vertiente', 'pea_ocupada',
  'pct_agua', 'pct_expuesto', 'pct_desacoplado', 'pct_construccion', 'pct_informal',
  'canal', 'flg_pesquero', 's_intrinseco', 's_demanda', 's_total', 'nivel'];
const out = [cab.join(',')];

for (const { d, cc } of filas) {
  let sh, pea = '';
  if (cc) { const t = Object.values(cc).reduce((a, b) => a + b, 0); pea = t; sh = {}; RAMAS.forEach(r => sh[r] = (cc[r] || 0) / t); }
  else sh = medRama(porProv[d.ub.slice(0, 4)]);
  if (!sh) { out.push([d.ub, d.dep, d.prov, d.dist, d.vert, '', '', '', '', '', '', '', '', '', '', '', 'SIN_DATO'].join(',')); continue; }

  const P = {}; LETRAS.forEach(p => P[p] = 0); RAMAS.forEach(r => P[RAMA[r]] += sh[r]);
  // pct por perfil redondeados a 1 dp (asi quedaron congelados; s se calcula sobre estos)
  const pc = {}; LETRAS.forEach(p => pc[p] = +(P[p] * 100).toFixed(1));

  const pesca = pescaPer[d.ub] || 0;
  const pacifico = String(d.vert).toUpperCase().indexOf('PACIF') >= 0;
  const flg = (pesca >= 10 && pacifico) ? 1 : 0;

  const pct_agua = pc.A, pct_expuesto = +(pc.B + pc.C).toFixed(1), pct_desacoplado = pc.D,
    pct_construccion = pc.E, pct_informal = pc.F;
  const w = flg ? 1.5 : 1.2;
  const s_int = w * pct_agua / 100 - 0.4 * pct_construccion / 100;
  const s_dem = 0.5 * (pct_agua / 100) * ((pct_expuesto + pct_informal) / 100);
  // s_total se recompone desde crudo (no es la suma de las columnas ya redondeadas: en el
  // congelado s_intrinseco+s_demanda != s_total en el ultimo decimal por el redondeo a 4 dp).
  const s_tot = (w * pct_agua - 0.4 * pct_construccion) / 100 + 0.5 * pct_agua * (pct_expuesto + pct_informal) / 10000;
  const s_intS = s_int.toFixed(4), s_demS = s_dem.toFixed(4), s_totS = s_tot.toFixed(4);

  out.push([d.ub, d.dep, d.prov, d.dist, d.vert, pea,
    pct_agua.toFixed(1), pct_expuesto.toFixed(1), pct_desacoplado.toFixed(1), pct_construccion.toFixed(1), pct_informal.toFixed(1),
    flg ? 'MAR' : 'TIERRA', flg, s_intS, s_demS, s_totS, nivelDe(+s_totS)].join(','));
}
fs.writeFileSync(B + '/02_pipeline/out/sectores_agua_distrito_REGEN.csv', out.join('\r\n') + '\r\n');
console.log('REGEN escrito:', out.length - 1, 'distritos');
