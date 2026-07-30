# =============================================================================
# EJECUTAR — Calibración PD Comportamental PP Reenganche
# =============================================================================
#   python Ejecutar.py                flujo completo
#   python Ejecutar.py --sin-reportes solo la cadena, sin generar los Excel
#   python Ejecutar.py --sin-macro    omite la selección macro F1-F8 (~30 s)
#   python Ejecutar.py --hasta 08     corta después del paso indicado
#
# ESTRUCTURA (rutas relativas a esta carpeta: la entrega es movible)
#   ../Data/          insumos     master_ree_v2.parquet, macro_feature_engineering_expanded.parquet
#   ./src/            módulos     config, calibration, vasicek, monitoring, metrics
#   ./sql/            consultas   la cadena que construye el maestro en Athena (no se corre acá)
#   ./pipeline/       LA CADENA   los 11 pasos que producen el resultado
#   ./analisis/       selección de variable macro (insumo de los gráficos)
#   ./reportes/       generadores del Excel — SEPARADOS de la cadena a propósito
#   ../Reportes/      salida      los Excel entregables
#   ../Resultados/    salida      json, csv, parquets, charts
#
# La separación pipeline/ vs reportes/ es deliberada: la cadena calcula la PD y
# los reportes sólo la presentan. Un cambio en el Excel no puede alterar un
# coeficiente, y el flujo corre completo con --sin-reportes.
# =============================================================================
import argparse
import os
import subprocess
import sys
import time
from pathlib import Path

AQUI = Path(__file__).resolve().parent
RAIZ = AQUI.parent
DATOS = RAIZ / 'Data'
RESULTADOS = RAIZ / 'Resultados'
REPORTES = RAIZ / 'Reportes'

CADENA = [
    ('pipeline/00_load_data.py',          'Carga y partición rd_hist / Z1 / Z2'),
    ('pipeline/01_rd_historica.py',       'RD histórica y LRA'),
    ('pipeline/02_vasicek_rho.py',        'Correlación de activos ρ'),
    ('analisis/macro_selection_f1_f8.py', 'Selección de variable macro F1-F8', 'macro'),
    ('pipeline/03_macro_ft.py',           'Modelo macro y factor sistémico ft'),
    ('pipeline/04_beta_calibration.py',   'Beta Calibration por segmento + anclaje TTC'),
    ('pipeline/05_lambda_mle.py',         'λ PIT por MLE binomial'),
    ('pipeline/06_pit_transformation.py', 'Transformación Vasicek PIT'),
    ('pipeline/07_monitoring.py',         'Monitoreo y semáforo'),
    ('pipeline/08_final_pd_table.py',     'Tabla final de PD'),
    ('pipeline/10_rd_projections.py',     'Proyección de cohortes inmaduras (V1)'),
    ('pipeline/11_charts_doc.py',         'Gráficos del documento'),
]
REPORTE = [
    ('reportes/09_excel_resumen.py',          'Excel resumen trimestral'),
    ('reportes/09b_excel_resumen_mensual.py', 'Excel resumen mensual'),
]

ap = argparse.ArgumentParser()
ap.add_argument('--sin-reportes', action='store_true')
ap.add_argument('--sin-macro', action='store_true')
ap.add_argument('--hasta', default=None)
args = ap.parse_args()

for d in ('parquets', 'json', 'csv', 'charts'):
    (RESULTADOS / d).mkdir(parents=True, exist_ok=True)
REPORTES.mkdir(parents=True, exist_ok=True)

falta = [f for f in ('master_ree_v2.parquet',
                     'macro_feature_engineering_expanded.parquet')
         if not (DATOS / f).exists()]
if falta:
    sys.exit(f"FALTAN DATOS en {DATOS}: {falta}")

env = dict(os.environ)
env['REE_DATA_DIR'] = str(DATOS)
env['REE_OUTDIR'] = str(RESULTADOS)
env['REE_REPORTES_DIR'] = str(REPORTES)
env['PYTHONIOENCODING'] = 'utf-8'   # la consola Windows es cp1252

print('=' * 78)
print('  CALIBRACIÓN PD — COMPORTAMENTAL PP REENGANCHE')
print('=' * 78)
print(f'  Datos      {DATOS}')
print(f'  Resultados {RESULTADOS}')
print(f'  Reportes   {REPORTES}')
print('=' * 78)

t0, fallos, corridos = time.time(), [], 0
plan = list(CADENA) + ([] if args.sin_reportes else list(REPORTE))
for paso in plan:
    rel, desc = paso[0], paso[1]
    if args.sin_macro and len(paso) > 2 and paso[2] == 'macro':
        print(f'  -- {Path(rel).stem:<26} omitido (--sin-macro)')
        continue
    nombre = Path(rel).stem
    t = time.time()
    r = subprocess.run([sys.executable, str(AQUI / rel)], cwd=str(AQUI), env=env,
                       capture_output=True, text=True, encoding='utf-8', errors='replace')
    log = RESULTADOS / f'_log_{nombre}.txt'
    log.write_text(r.stdout + r.stderr, encoding='utf-8')   # el detalle NO se descarta
    if r.returncode != 0:
        print(f'  XX {nombre:<26} FALLÓ ({time.time()-t:.1f}s) — {desc}')
        print('     ' + '\n     '.join((r.stdout + r.stderr).strip().splitlines()[-8:]))
        fallos.append(nombre)
        break
    corridos += 1
    print(f'  ok {nombre:<26} {time.time()-t:6.1f}s   {desc}')
    if args.hasta and args.hasta in nombre:
        print(f'  -- corte solicitado en {nombre}')
        break

print('=' * 78)
if fallos:
    print(f'  FALLÓ en: {", ".join(fallos)}   ({time.time()-t0:.1f}s)')
    sys.exit(1)
# Sólo se declara completo si se corrió TODO el plan (un --hasta no es completo).
completo = corridos == len([p for p in plan
                            if not (args.sin_macro and len(p) > 2 and p[2] == 'macro')])
print(f'  {"FLUJO COMPLETO" if completo else "FLUJO PARCIAL"} — {corridos} pasos '
      f'en {time.time()-t0:.1f}s')
print(f'  Detalle por paso en {RESULTADOS}/_log_*.txt')
sys.exit(0 if completo else 2)
