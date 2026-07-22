'use strict';
// Ejecuta cada .sql de 10_rd_codmes/ y 20_composicion/ en Athena (vía AWS CLI)
// y vuelca los resultados a un Excel multi-hoja en resultados/.
const { execSync } = require('child_process');
const fs = require('fs'); const path = require('path');
const XLSX = require('C:/Users/CARLOS/elnino_ibk/02_pipeline/node_modules/xlsx');
const DIR = __dirname;
const OUT = path.join(DIR, 'resultados');
fs.mkdirSync(OUT, { recursive: true });
const PROFILE = 'ibk', REGION = 'us-east-1', WG = 'ibk-discovery-riesgos-work-group', DB = 'disc_model_owner';
const fold = s => s.normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/[^\x00-\x7F]/g, '');
const sh = c => execSync(c, { stdio: ['ignore', 'pipe', 'pipe'], maxBuffer: 1 << 26 }).toString().trim();
const sleep2 = () => { try { sh(process.platform === 'win32' ? 'ping -n 3 127.0.0.1' : 'sleep 2'); } catch (e) {} };

function runSql(sqlText) {
  const clean = fold(sqlText).replace(/;\s*$/, '');
  const tmp = path.join(OUT, '_tmp.sql'); fs.writeFileSync(tmp, clean, 'utf8');
  const fileUri = 'file://' + tmp.replace(/\\/g, '/');
  const id = sh(`aws athena start-query-execution --profile ${PROFILE} --region ${REGION} --work-group ${WG} --query-execution-context Database=${DB} --query-string ${fileUri} --output text --query QueryExecutionId`);
  let state = '';
  for (let i = 0; i < 150; i++) {
    state = sh(`aws athena get-query-execution --profile ${PROFILE} --region ${REGION} --query-execution-id ${id} --output text --query QueryExecution.Status.State`);
    if (['SUCCEEDED', 'FAILED', 'CANCELLED'].includes(state)) break;
    sleep2();
  }
  if (state !== 'SUCCEEDED') {
    let reason = ''; try { reason = sh(`aws athena get-query-execution --profile ${PROFILE} --region ${REGION} --query-execution-id ${id} --output text --query QueryExecution.Status.StateChangeReason`); } catch (e) {}
    throw new Error(state + ' :: ' + reason);
  }
  const loc = sh(`aws athena get-query-execution --profile ${PROFILE} --region ${REGION} --query-execution-id ${id} --output text --query QueryExecution.ResultConfiguration.OutputLocation`);
  const localCsv = path.join(OUT, '_tmp.csv');
  sh(`aws s3 cp ${loc} ${localCsv.replace(/\\/g, '/')} --profile ${PROFILE} --region ${REGION}`);
  return fs.readFileSync(localCsv, 'utf8');
}

const groups = [
  ['10_rd_codmes', ['rd_stock_tc', 'rd_stock_pp', 'rd_stock_vc', 'rd_altas_tc', 'rd_altas_pp', 'rd_altas_vc']],
  ['20_composicion', ['npct_stock_tc', 'npct_stock_pp', 'npct_stock_vc', 'npct_altas_tc_pp']],
];
const wb = XLSX.utils.book_new();
for (const [sub, files] of groups) {
  for (const f of files) {
    const p = path.join(DIR, sub, f + '.sql');
    if (!fs.existsSync(p)) { console.log('SKIP (falta) ' + f); continue; }
    process.stdout.write('ejecutando ' + f + ' ... ');
    try {
      const csv = runSql(fs.readFileSync(p, 'utf8'));
      const tmpWb = XLSX.read(csv, { type: 'string' });
      const ws = tmpWb.Sheets[tmpWb.SheetNames[0]];
      XLSX.utils.book_append_sheet(wb, ws, f.slice(0, 31));
      const rows = XLSX.utils.sheet_to_json(ws).length;
      console.log('OK (' + rows + ' filas)');
    } catch (e) { console.log('ERROR ' + e.message); }
  }
}
function safeWrite(book, primary) {
  try { XLSX.writeFile(book, primary); return primary; }
  catch (e) {
    if (e.code === 'EBUSY' || e.code === 'EPERM') {
      const alt = primary.replace(/\.xlsx$/, '_NEW.xlsx');
      XLSX.writeFile(book, alt);
      console.log('(!) ' + path.basename(primary) + ' estaba bloqueado (abierto en Excel) -> escribi ' + path.basename(alt));
      return alt;
    } throw e;
  }
}
const outFile = safeWrite(wb, path.join(OUT, 'RD_grupos_FEN.xlsx'));
try { fs.unlinkSync(path.join(OUT, '_tmp.sql')); fs.unlinkSync(path.join(OUT, '_tmp.csv')); } catch (e) {}
console.log('\nESCRITO: ' + outFile + '  | hojas: ' + wb.SheetNames.join(', '));
