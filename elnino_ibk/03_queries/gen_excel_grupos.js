'use strict';
// Genera RD_grupos_consol_FEN.xlsx: RD y %n por grupos consolidados
// (G0_noPac=R0 | G1_Bajo=R1 | G2_Medio=R2+R3 | G3_Alto=R4+R5) x codmes, por libro.
// Capa de lectura (CASE sobre r_label) — NO modifica ninguna tabla.
const { execSync } = require('child_process');
const fs = require('fs'); const path = require('path');
const XLSX = require('C:/Users/CARLOS/elnino_ibk/02_pipeline/node_modules/xlsx');
const OUT = path.join(__dirname, 'resultados'); fs.mkdirSync(OUT, { recursive: true });
const PROFILE = 'ibk', REGION = 'us-east-1', WG = 'ibk-discovery-riesgos-work-group', DB = 'disc_model_owner';
const fold = s => s.normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/[^\x00-\x7F]/g, '');
const sh = c => execSync(c, { stdio: ['ignore', 'pipe', 'pipe'], maxBuffer: 1 << 26 }).toString().trim();
const sleep2 = () => { try { sh(process.platform === 'win32' ? 'ping -n 3 127.0.0.1' : 'sleep 2'); } catch (e) {} };
function runSql(sqlText) {
  const clean = fold(sqlText).replace(/;\s*$/, '');
  const tmp = path.join(OUT, '_tmpg.sql'); fs.writeFileSync(tmp, clean, 'utf8');
  const id = sh(`aws athena start-query-execution --profile ${PROFILE} --region ${REGION} --work-group ${WG} --query-execution-context Database=${DB} --query-string file://${tmp.replace(/\\/g, '/')} --output text --query QueryExecutionId`);
  let st = '';
  for (let i = 0; i < 150; i++) { st = sh(`aws athena get-query-execution --profile ${PROFILE} --region ${REGION} --query-execution-id ${id} --output text --query QueryExecution.Status.State`); if (['SUCCEEDED', 'FAILED', 'CANCELLED'].includes(st)) break; sleep2(); }
  if (st !== 'SUCCEEDED') { let r = ''; try { r = sh(`aws athena get-query-execution --profile ${PROFILE} --region ${REGION} --query-execution-id ${id} --output text --query QueryExecution.Status.StateChangeReason`); } catch (e) {} throw new Error(st + ' :: ' + r); }
  const loc = sh(`aws athena get-query-execution --profile ${PROFILE} --region ${REGION} --query-execution-id ${id} --output text --query QueryExecution.ResultConfiguration.OutputLocation`);
  const lc = path.join(OUT, '_tmpg.csv'); sh(`aws s3 cp ${loc} ${lc.replace(/\\/g, '/')} --profile ${PROFILE} --region ${REGION}`);
  return fs.readFileSync(lc, 'utf8');
}
const JOIN = `JOIN disc_model_owner.grado_elnino_lookup_v3 g
  ON regexp_replace(normalize(t.dep_ubi_domicilio,NFD),'\\p{M}','')=g.dep
 AND regexp_replace(normalize(t.pro_ubi_domicilio,NFD),'\\p{M}','')=g.prov
 AND regexp_replace(normalize(t.dis_ubi_domicilio,NFD),'\\p{M}','')=g.dist`;
const GC = `CASE WHEN g.r_label='R0' THEN 'G0_noPac' WHEN g.r_label='R1' THEN 'G1_Bajo' WHEN g.r_label IN ('R2','R3') THEN 'G2_Medio' ELSE 'G3_Alto' END`;
const rdSQL = (table, d, where) => `WITH j AS (SELECT ${GC} grupo, t.codmes, ${d} d FROM disc_model_owner.${table} t ${JOIN} WHERE ${where})
SELECT codmes, count(*) n,
 round(100.0*avg(CASE WHEN grupo='G1_Bajo'  THEN d END),2) G1_Bajo,
 round(100.0*avg(CASE WHEN grupo='G2_Medio' THEN d END),2) G2_Medio,
 round(100.0*avg(CASE WHEN grupo='G3_Alto'  THEN d END),2) G3_Alto,
 round(100.0*avg(CASE WHEN grupo='G0_noPac' THEN d END),2) G0_noPac,
 round(100.0*(avg(CASE WHEN grupo='G3_Alto' THEN d END)-avg(CASE WHEN grupo='G1_Bajo' THEN d END)),2) spread_Alto_Bajo
FROM j GROUP BY codmes ORDER BY codmes`;
const npctSQL = (table, where) => `WITH j AS (SELECT ${GC} grupo, t.codmes FROM disc_model_owner.${table} t ${JOIN} WHERE ${where})
SELECT codmes, count(*) n_total,
 round(100.0*sum(CASE WHEN grupo='G0_noPac' THEN 1 ELSE 0 END)/count(*),2) pct_G0_noPac,
 round(100.0*sum(CASE WHEN grupo='G1_Bajo'  THEN 1 ELSE 0 END)/count(*),2) pct_G1_Bajo,
 round(100.0*sum(CASE WHEN grupo='G2_Medio' THEN 1 ELSE 0 END)/count(*),2) pct_G2_Medio,
 round(100.0*sum(CASE WHEN grupo='G3_Alto'  THEN 1 ELSE 0 END)/count(*),2) pct_G3_Alto
FROM j GROUP BY codmes ORDER BY codmes`;
const books = [
  ['rd_stock_tc', rdSQL('ENR_STOCK_TC_FEM_3', 'CAST(t.def12 AS double)', 't.def12 IS NOT NULL')],
  ['rd_stock_pp', rdSQL('ENR_STOCK_PP_FEM_3', 'CAST(t.def12 AS double)', 't.def12 IS NOT NULL')],
  ['rd_stock_vc', rdSQL('ENR_STOCK_VC_FEM_3', 'CAST(t.def12_vc AS double)', 't.def12_vc IS NOT NULL')],
  ['rd_altas_tc', rdSQL('ENR_VC_FEM_3', "CASE WHEN t.tipo_cliente_tc='2.MALO' THEN 1.0 ELSE 0.0 END", "t.tipo_producto='SOLO_TC' AND t.tipo_cliente_tc IN ('2.MALO','5.BUENO') AND t.DEF12_TC IS NOT NULL")],
  ['rd_altas_pp', rdSQL('ENR_VC_FEM_3', "CASE WHEN t.tipo_cliente_PP='MALO' THEN 1.0 ELSE 0.0 END", "t.tipo_producto='SOLO_PP' AND t.tipo_cliente_PP IN ('BUENO','MALO') AND t.DEF12_PP IS NOT NULL")],
  ['rd_altas_vc', rdSQL('ENR_VC_FEM_3', 'CAST(t.DEF12_VC_ AS double)', 't.DEF12_VC_ IS NOT NULL')],
  ['npct_stock_tc', npctSQL('ENR_STOCK_TC_FEM_3', '1=1')],
  ['npct_stock_pp', npctSQL('ENR_STOCK_PP_FEM_3', '1=1')],
  ['npct_stock_vc', npctSQL('ENR_STOCK_VC_FEM_3', '1=1')],
  ['npct_altas', npctSQL('ENR_VC_FEM_3', '1=1')],
];
const wb = XLSX.utils.book_new();
for (const [name, sql] of books) {
  process.stdout.write('ejecutando ' + name + ' ... ');
  try { const ws = XLSX.read(runSql(sql), { type: 'string' }); XLSX.utils.book_append_sheet(wb, ws.Sheets[ws.SheetNames[0]], name); console.log('OK'); }
  catch (e) { console.log('ERROR ' + e.message); }
}
function safeWrite(book, primary) { try { XLSX.writeFile(book, primary); return primary; } catch (e) { if (e.code === 'EBUSY' || e.code === 'EPERM') { const a = primary.replace(/\.xlsx$/, '_NEW.xlsx'); XLSX.writeFile(book, a); return a; } throw e; } }
const f = safeWrite(wb, path.join(OUT, 'RD_grupos_consol_FEN.xlsx'));
try { fs.unlinkSync(path.join(OUT, '_tmpg.sql')); fs.unlinkSync(path.join(OUT, '_tmpg.csv')); } catch (e) {}
console.log('\nESCRITO: ' + f + ' | hojas: ' + wb.SheetNames.join(', '));
