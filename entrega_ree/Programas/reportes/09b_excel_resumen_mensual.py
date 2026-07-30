# =============================================================================
# 09b — Excel resumen MENSUAL por driver (Reenganche)
# =============================================================================
# Misma estructura que 09 trimestral pero a nivel mes.
# EC convention: EC = (PD/RD - 1) × 100 (pp), misma que 09.
# =============================================================================

import json
import warnings
from pathlib import Path

import numpy as np
import pandas as pd
from scipy.stats import norm

warnings.filterwarnings("ignore")

import sys

_PROJECT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(_PROJECT / 'src'))

from config import (
    RANDOM_SEED, PATHS, TARGET_COL, SCORE_COL, SUBPRODUCTO_FILTER,
    SEG_COL, DRIVER_COLS, COHORTE_FIN, COVID_EXCL_MONTHS,
    MACRO_CHAMPION_VARS, SCORE_INI, RD_HIST_FIN,
)
from monitoring import ec_relativo, ec_status, jeffreys_pass

np.random.seed(RANDOM_SEED)

# Destino del xlsx. Por defecto el mismo outdir que el resto (PATHS resuelve
# REE_OUTDIR); REE_REPORTES_DIR lo manda a una carpeta aparte, que es como viaja
# en la entrega: el Excel es un ENTREGABLE y vive separado de los intermedios.
import os as _os
OUTPUT_DIR = (Path(_os.environ['REE_REPORTES_DIR']) if _os.environ.get('REE_REPORTES_DIR')
              else PATHS['json'].parent)
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

MESES_RANGE = [f"{y}{m:02d}" for y in range(2019, 2027) for m in range(1, 13)]
MESES_RANGE = [m for m in MESES_RANGE if SCORE_INI <= m <= RD_HIST_FIN]

PD_SERIES = ['pd', 'pd_ttc_adj', 'pd_pit', 'pd_pit_floor']

# =============================================================================
# 1. Carga
# =============================================================================

print("=" * 60)
print(f"  09b — EXCEL RESUMEN MENSUAL {SUBPRODUCTO_FILTER}")
print("=" * 60)

df = pd.read_parquet(PATHS['parquets'] / 'full_calibrated.parquet')
df['codmes'] = df['codmes'].astype(str)
df = df[df['codmes'].isin(MESES_RANGE)].copy()
print(f"Loaded: {len(df):,} obs, {df['codmes'].nunique()} meses")

with open(PATHS['json'] / 'pit_transformation.json') as f:
    pit_params = json.load(f)
with open(PATHS['json'] / 'vasicek_rho.json') as f:
    rho_params = json.load(f)
with open(PATHS['json'] / 'macro_model.json') as f:
    macro_params = json.load(f)
with open(PATHS['json'] / 'lra.json') as f:
    lra_params = json.load(f)
with open(PATHS['json'] / 'calibracion_beta.json') as f:
    cal_params = json.load(f)

lambda_params = {}
lambda_path = PATHS['json'] / 'lambda_mle_binomial.json'
if lambda_path.exists():
    with open(lambda_path) as f:
        lambda_params = json.load(f)

proj_params = {}
proj_path = PATHS['json'] / 'rd_projections.json'
if proj_path.exists():
    with open(proj_path) as f:
        proj_params = json.load(f)

proj_dict_global = {}
if proj_params:
    for p in proj_params.get('global', {}).get('projections', []):
        proj_dict_global[p['codmes']] = p

# Proyeccion por celda de driver. 10_rd_projections estima los factores de
# desarrollo sobre el triangulo de CADA celda, no prorratea el global: una celda
# con maduracion mas lenta arrastra su propio factor.
proj_dict_driver = {}
if proj_params:
    for _eje, _celdas in proj_params.get('by_driver', {}).items():
        for _v, _d in _celdas.items():
            for p in _d.get('projections', []):
                proj_dict_driver[(_eje, str(_v), p['codmes'])] = p

PROY_VARIANTES = [('RD12_proj', 'rd12_proj'),
                  ('RD_PROY', 'rd12_proj_mediana'),
                  ('RD_PROY_V1', 'rd12_proj_v1'),
                  ('RD_PROY_V2', 'rd12_proj_v2'),
                  ('RD_PROY_V3_MOM', 'rd12_proj_v3_mom'),
                  ('RD_PROY_V3', 'rd12_proj_v3')]

NOTAS_DRIVER = [
    'RD observada (RD_12m..RD_3m): las celdas SI recomponen el GLOBAL ponderando '
    'por N — es una particion, la diferencia medida es 0,0000 pp.',
    'RD proyectada (RD12_proj y RD_PROY*): NO recompone el GLOBAL. Cada celda estima '
    'su propio factor de desarrollo sobre su propio triangulo, y el cuantil adaptativo '
    'de V1 no es lineal. La diferencia medida llega a 0,44 pp. Es una vista POR CELDA, '
    'no una descomposicion del GLOBAL: no se deben sumar.',
]

ft_cal = pd.read_csv(PATHS['csv'] / 'ft_calendario.csv')
ft_cal['codmes'] = ft_cal['codmes'].astype(str)
ft_cal['rd_pred_macro'] = norm.cdf(ft_cal['ft_GLOBAL'].values)
ft_dict = dict(zip(ft_cal['codmes'], ft_cal['rd_pred_macro']))

if 'pd_pit' in df.columns and 'pd_ttc_adj' in df.columns:
    df['pd_pit_floor'] = np.maximum(df['pd_pit'], df['pd_ttc_adj'])

MONTHS = sorted(df['codmes'].unique())

# =============================================================================
# 2. EC / Jeffreys / Status  (estandar unico en src/monitoring.py:
#    bandas EC x2 Low Default + downgrade por test de Jeffreys bilateral p>5%)
# =============================================================================


def add_ec_columns(row, rd, n_target, defaults, pd_val, suffix):
    if np.isnan(rd) or rd <= 0 or np.isnan(pd_val):
        row[f'EC_{suffix}'] = np.nan
        row[f'J_{suffix}'] = ''
        row[f'ST_{suffix}'] = ''
        return
    ec = ec_relativo(rd, pd_val)              # (RD-PD)/PD ; EC>0 = subestimacion
    row[f'EC_{suffix}'] = ec
    j_pass = jeffreys_pass(defaults, n_target, pd_val)
    row[f'J_{suffix}'] = 'PASS' if j_pass else ('FAIL' if j_pass is not None else '')
    st = ec_status(ec, bool(j_pass) if j_pass is not None else False)
    row[f'ST_{suffix}'] = st.upper() if st != 'nan' else ''


# =============================================================================
# 3. Sheet builders (MENSUAL)
# =============================================================================


def build_global_sheet(df_):
    rows = []
    for cm in MONTHS:
        sub = df_[df_['codmes'] == cm]
        n = len(sub)
        if n == 0:
            continue

        row = {'codmes': cm, 'N': n}

        for s in PD_SERIES:
            if s in sub.columns:
                row[s] = sub[s].mean()

        is_z1 = cm <= COHORTE_FIN
        has_target = TARGET_COL in sub.columns

        if is_z1 and has_target:
            valid = sub[sub[TARGET_COL].notna()]
            total_def = int(valid[TARGET_COL].sum())
            total_n = len(valid)
            row['defaults'] = total_def
            row['N_target'] = total_n
            row['RD'] = total_def / total_n if total_n > 0 else np.nan
        else:
            row['defaults'] = np.nan
            row['N_target'] = np.nan
            row['RD'] = np.nan
            _p = proj_dict_global.get(cm)
            if _p:
                # RD12_proj = la seleccionada por PROY_METODO; el resto al lado
                # con los nombres del Excel de Comportamental BN.
                row['RD12_proj'] = _p['rd12_proj']
                for _dst, _src in [('RD_PROY', 'rd12_proj_mediana'),
                                   ('RD_PROY_V1', 'rd12_proj_v1'),
                                   ('RD_PROY_V2', 'rd12_proj_v2'),
                                   ('RD_PROY_V3_MOM', 'rd12_proj_v3_mom'),
                                   ('RD_PROY_V3', 'rd12_proj_v3')]:
                    if _p.get(_src) is not None:
                        row[_dst] = _p[_src]

        # RD observada a cada horizonte 12m..3m. Se calcula por horizonte y NO
        # bajo `is_z1`: un periodo puede tener rd_3m cerrado y rd_12m todavia no,
        # porque cada horizonte madura un mes mas tarde que el siguiente. Es el
        # triangulo de desarrollo sobre el que se apoya la proyeccion.
        for _h in range(12, 2, -1):
            _c = f'target_{_h}m'
            if _c in sub.columns:
                _v = sub[_c].dropna()
                row[f'RD_{_h}m'] = float(_v.sum() / len(_v)) if len(_v) > 0 else np.nan
            else:
                row[f'RD_{_h}m'] = np.nan
        row['rd_pred_macro'] = ft_dict.get(cm, np.nan)

        rd_val = row.get('RD', np.nan)
        n_tgt = row.get('N_target', 0)
        dflts = row.get('defaults', np.nan)
        for s in PD_SERIES:
            if s in row and not (isinstance(row[s], float) and np.isnan(row[s])):
                add_ec_columns(row, rd_val, n_tgt, dflts, row[s], s)
            else:
                row[f'EC_{s}'] = np.nan
                row[f'J_{s}'] = ''
                row[f'ST_{s}'] = ''

        rows.append(row)

    result = pd.DataFrame(rows)
    pd_block = []
    for s in PD_SERIES:
        pd_block += [s, f'EC_{s}', f'J_{s}', f'ST_{s}']
    col_order = ['codmes', 'N', 'N_target', 'defaults', 'RD']
    col_order += [f'RD_{h}m' for h in range(12, 2, -1)]
    if 'RD12_proj' in result.columns:
        col_order += ['RD12_proj']
    col_order += ['RD_PROY', 'RD_PROY_V1', 'RD_PROY_V2', 'RD_PROY_V3_MOM', 'RD_PROY_V3']
    col_order += pd_block + ['rd_pred_macro']
    col_order = [c for c in col_order if c in result.columns]
    return result[col_order]


def build_driver_sheet(df_, driver):
    if driver not in df_.columns:
        return pd.DataFrame()

    df_drv = df_[df_[driver].notna()].copy()
    values = sorted(df_drv[driver].unique(), key=str)

    rows = []
    for cm in MONTHS:
        sub_cm = df_drv[df_drv['codmes'] == cm]
        if len(sub_cm) == 0:
            continue

        row = {'codmes': cm}

        for val in values:
            v = str(val)
            mask_val = sub_cm[driver].astype(str) == v
            sub_val = sub_cm[mask_val]
            n = len(sub_val)

            row[f'N_{v}'] = n

            for s in PD_SERIES:
                if s in sub_val.columns and n > 0:
                    row[f'{s}_{v}'] = sub_val[s].mean()
                else:
                    row[f'{s}_{v}'] = np.nan

            is_z1 = cm <= COHORTE_FIN

            if is_z1 and TARGET_COL in sub_val.columns and n > 0:
                valid = sub_val[sub_val[TARGET_COL].notna()]
                total_def = int(valid[TARGET_COL].sum()) if len(valid) > 0 else 0
                total_n = len(valid)
                row[f'defaults_{v}'] = total_def
                row[f'RD_{v}'] = total_def / total_n if total_n > 0 else np.nan
            else:
                total_n = 0
                row[f'defaults_{v}'] = np.nan
                row[f'RD_{v}'] = np.nan

            # RD observada a cada horizonte 12m..3m, fuera de `is_z1` por lo mismo
            # que en GLOBAL: cada horizonte cierra un mes antes que el siguiente.
            for _h in range(12, 2, -1):
                _c = f'target_{_h}m'
                if _c in sub_val.columns and n > 0:
                    _s = sub_val[_c].dropna()
                    row[f'RD_{_h}m_{v}'] = float(_s.sum() / len(_s)) if len(_s) > 0 else np.nan
                else:
                    row[f'RD_{_h}m_{v}'] = np.nan

            _p = proj_dict_driver.get((driver, v, cm))
            if _p:
                for _dst, _src in PROY_VARIANTES:
                    if _p.get(_src) is not None:
                        row[f'{_dst}_{v}'] = _p[_src]

            rd_drv = row.get(f'RD_{v}', np.nan)
            n_drv = total_n          # el denominador de Jeffreys es el N con target
            d_drv = row.get(f'defaults_{v}', np.nan)
            for s in PD_SERIES:
                col_s = f'{s}_{v}'
                if col_s in row and not (isinstance(row[col_s], float) and np.isnan(row[col_s])):
                    add_ec_columns(row, rd_drv, n_drv, d_drv, row[col_s], f'{s}_{v}')
                else:
                    row[f'EC_{s}_{v}'] = np.nan
                    row[f'J_{s}_{v}'] = ''
                    row[f'ST_{s}_{v}'] = ''

        row['rd_pred_macro'] = ft_dict.get(cm, np.nan)
        rows.append(row)

    result = pd.DataFrame(rows)
    col_order = ['codmes']
    for val in values:
        v = str(val)
        pd_drv_block = []
        for s in PD_SERIES:
            pd_drv_block += [f'{s}_{v}', f'EC_{s}_{v}', f'J_{s}_{v}', f'ST_{s}_{v}']
        col_order += [f'N_{v}', f'defaults_{v}', f'RD_{v}']
        col_order += [f'RD_{h}m_{v}' for h in range(12, 2, -1)]
        col_order += [f'{d}_{v}' for d, _ in PROY_VARIANTES]
        col_order += pd_drv_block
    col_order += ['rd_pred_macro']
    col_order = [c for c in col_order if c in result.columns]
    return result[col_order]


# =============================================================================
# 4. Formatting
# =============================================================================


def format_sheet(ws, df_, writer, notas_extra=None):
    workbook = writer.book
    fmt_pct = workbook.add_format({'num_format': '0.00%', 'align': 'center'})
    fmt_ec = workbook.add_format({'num_format': '+0.0%;-0.0%', 'align': 'center'})
    fmt_int = workbook.add_format({'num_format': '#,##0', 'align': 'center'})
    fmt_text = workbook.add_format({'align': 'center'})
    fmt_header = workbook.add_format({
        'bold': True, 'align': 'center', 'bg_color': '#002060',
        'font_color': 'white', 'border': 1,
    })
    fmt_verde = workbook.add_format({
        'align': 'center', 'bg_color': '#C6EFCE', 'font_color': '#006100', 'bold': True})
    fmt_amarillo = workbook.add_format({
        'align': 'center', 'bg_color': '#FFEB9C', 'font_color': '#9C6500', 'bold': True})
    fmt_rojo = workbook.add_format({
        'align': 'center', 'bg_color': '#FFC7CE', 'font_color': '#9C0006', 'bold': True})

    for col_idx, col_name in enumerate(df_.columns):
        ws.set_column(col_idx, col_idx, 14)
        if col_name == 'codmes':
            ws.set_column(col_idx, col_idx, 10, fmt_text)
        elif col_name.startswith('N') or col_name.startswith('defaults'):
            ws.set_column(col_idx, col_idx, 12, fmt_int)
        elif col_name.startswith('EC_'):
            ws.set_column(col_idx, col_idx, 10, fmt_ec)
        elif col_name.startswith(('J_', 'ST_')):
            ws.set_column(col_idx, col_idx, 10, fmt_text)
        elif col_name.startswith(('RD', 'rd_', 'pd_')):
            ws.set_column(col_idx, col_idx, 12, fmt_pct)
        elif col_name.startswith('rd_pred_macro'):
            ws.set_column(col_idx, col_idx, 12, fmt_pct)

    for col_idx, col_name in enumerate(df_.columns):
        ws.write(0, col_idx, col_name, fmt_header)

    for col_idx, col_name in enumerate(df_.columns):
        if col_name.startswith('ST_'):
            for row_idx in range(len(df_)):
                val = df_.iloc[row_idx, col_idx]
                excel_row = row_idx + 1
                if val == 'VERDE':
                    ws.write(excel_row, col_idx, val, fmt_verde)
                elif val == 'AMARILLO':
                    ws.write(excel_row, col_idx, val, fmt_amarillo)
                elif val == 'ROJO':
                    ws.write(excel_row, col_idx, val, fmt_rojo)
                else:
                    ws.write(excel_row, col_idx, val or '', fmt_text)

    if notas_extra:
        fmt_note = workbook.add_format({'align': 'left', 'text_wrap': True, 'valign': 'top'})
        note_col = len(df_.columns) + 2
        ws.set_column(note_col, note_col, 40)
        ws.write(0, note_col, 'NOTAS', fmt_header)
        for i, txt in enumerate(notas_extra):
            ws.write(i + 1, note_col, txt, fmt_note)


# =============================================================================
# 5. Generate Excel
# =============================================================================

xlsx_path = OUTPUT_DIR / f'resumen_mensual_{SUBPRODUCTO_FILTER}.xlsx'

with pd.ExcelWriter(xlsx_path, engine='xlsxwriter') as writer:

    # ── GLOBAL sheet ──
    global_df = build_global_sheet(df)
    global_df.to_excel(writer, sheet_name='GLOBAL', index=False, startrow=1, header=False)
    ws = writer.sheets['GLOBAL']
    format_sheet(ws, global_df, writer)
    print(f"  Sheet GLOBAL: {len(global_df)} rows, {len(global_df.columns)} cols")

    # ── Driver sheets ──
    for drv in DRIVER_COLS:
        if drv not in df.columns:
            print(f"  Sheet {drv}: SKIP (not in data)")
            continue
        drv_df = build_driver_sheet(df, drv)
        if len(drv_df) == 0:
            print(f"  Sheet {drv}: SKIP (empty)")
            continue
        sheet_name = drv[:31]
        drv_df.to_excel(writer, sheet_name=sheet_name, index=False, startrow=1, header=False)
        ws = writer.sheets[sheet_name]
        format_sheet(ws, drv_df, writer, NOTAS_DRIVER)
        print(f"  Sheet {sheet_name}: {len(drv_df)} rows, {len(drv_df.columns)} cols")

print(f"\nExport: {xlsx_path}")

print(f"\n{'=' * 60}")
print(f"  09b COMPLETADO — EXCEL RESUMEN MENSUAL {SUBPRODUCTO_FILTER}")
print(f"{'=' * 60}")
