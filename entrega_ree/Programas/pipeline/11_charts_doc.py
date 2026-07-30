# =============================================================================
# 11 — Gráficos para doc metodológico (Reenganche)
# =============================================================================
# Estilo paper con color. Convenciones de serie:
#   RD histórico cerrado : marcador circular navy, sin línea.
#   RD proyectada (Z2)   : marcador circular rojo, sin línea.
#   PD PIT               : línea sólida suavizada, verde Interbank, sin marcador.
# Eje X en formato fecha MMM-YY. Export: PNG 320dpi + PDF por chart.
# =============================================================================

import json
import warnings
from pathlib import Path

import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.ticker as mtick
from matplotlib.patches import Patch
from scipy.stats import norm

warnings.filterwarnings("ignore")

import sys

_PROJECT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(_PROJECT / 'src'))

from config import (
    RANDOM_SEED, PATHS, TARGET_COL, SCORE_COL, SUBPRODUCTO_FILTER,
    SEG_COL, SEG_VALUES, DRIVER_COLS, LAMBDA_PIT, COHORTE_FIN,
    COVID_EXCL_MONTHS, RD_HIST_INI, RD_HIST_FIN, F_CAP_QUANTILE,
    COHORTE_INI, RHO_FLOOR, LRA_EXCL_MONTHS,
)
from metrics import jeffreys_ic

np.random.seed(RANDOM_SEED)

CHART_DIR = PATHS['charts']
CHART_DIR.mkdir(parents=True, exist_ok=True)

# =============================================================================
# PLOT STYLE — Reference: PP/outputs/images/
# Open markers, hatched bars, dash-dot LRA, serif font, bottom+left spines.
# =============================================================================

MUTED = '#4D4D4D'
LIGHT = '#D0D0D0'
GRID_C = '#E8E8E8'
HATCHES = ['////', '....', '\\\\\\\\', 'xxxx', '----', '++++', 'oooo']

# Semaphore colors (only for traffic-light dots)
SEM_GREEN = '#2E8B57'
SEM_YELLOW = '#DAA520'
SEM_RED = '#B22222'

# --- Paleta de series (paper, color) ---
NAVY = '#16365C'        # RD historico observada (marcador circular)
RD_RED = '#C0392B'      # RD proyectada Z2 (marcador circular)
IBK_GREEN = '#00A94F'   # PD PIT (verde Interbank, linea suavizada)
TTC_GRAY = '#6E6E6E'    # PD TTC
RAW_GRAY = '#AFAFAF'    # PD raw
BAND_BLUE = '#BFD3E6'   # bandas de confianza
CAT_COLORS = ['#16365C', '#C0392B', '#00A94F', '#E08A1E', '#7D3C98', '#117A65']

from scipy.interpolate import make_interp_spline


def smooth_xy(x, y, n=300):
    """Curva suavizada (spline cubico) estilo linea suave de Excel. Robusta a NaN."""
    x = np.asarray(x, dtype=float)
    y = np.asarray(y, dtype=float)
    m = np.isfinite(x) & np.isfinite(y)
    x, y = x[m], y[m]
    if len(x) < 4:
        return x, y
    xs = np.linspace(x.min(), x.max(), n)
    return xs, make_interp_spline(x, y, k=min(3, len(x) - 1))(xs)


def plot_rd_hist(ax, x, y, label='RD12 observada', ms=7, color=NAVY):
    """RD historico cerrado: marcador circular relleno navy, sin linea."""
    return ax.plot(x, y, ls='none', marker='o', ms=ms, color=color,
                   markeredgecolor='white', markeredgewidth=0.5, label=label, zorder=5)


def plot_rd_proj(ax, x, y, label='RD12 proyectada (Z2)', ms=7):
    """RD proyecciones: marcador circular relleno rojo, sin linea."""
    return ax.plot(x, y, ls='none', marker='o', ms=ms, color=RD_RED,
                   markeredgecolor='white', markeredgewidth=0.5, label=label, zorder=5)


def plot_pit(ax, x, y, label='PD PIT', lw=2.4, color=IBK_GREEN):
    """PD PIT: linea solida suavizada verde Interbank, sin marcadores."""
    xs, ys = smooth_xy(x, y)
    return ax.plot(xs, ys, color=color, lw=lw, solid_capstyle='round',
                   solid_joinstyle='round', label=label, zorder=4)


def line_smooth(ax, x, y, color=TTC_GRAY, ls='--', lw=1.3, label=None):
    """Linea suavizada (coherencia: si hay PIT suavizada, todas las lineas se suavizan)."""
    xs, ys = smooth_xy(x, y)
    return ax.plot(xs, ys, color=color, ls=ls, lw=lw, label=label)


def jeffreys_band(rd_arr, n_arr, q_lo=0.025, q_hi=0.975):
    """IC creible Jeffreys de la RD observada por periodo: cuantiles [q_lo, q_hi] del
    posterior Beta(k+0.5, n-k+0.5), con k = round(RD*N). Default 95% (q2.5/q97.5),
    igual al test de status del Excel. NaN donde no hay RD observada."""
    from scipy.stats import beta
    rd = np.asarray(rd_arr, dtype=float)
    n = np.asarray(n_arr, dtype=float)
    k = np.round(rd * n)
    lo = beta.ppf(q_lo, k + 0.5, n - k + 0.5)
    hi = beta.ppf(q_hi, k + 0.5, n - k + 0.5)
    return lo, hi


def to_quarter(codmes):
    cm = str(codmes)
    return f"{cm[:4]}Q{(int(cm[4:6]) - 1) // 3 + 1}"


def fmt_q(q):
    """2024Q1 -> '1T-24' (etiqueta trimestral)."""
    return f"{q[-1]}T-{q[2:4]}"


def quarter_series(df_sub, proj_list=None):
    """Agrega a trimestre: pd_pit, pd_ttc, pd_ttc_adj, n, RD observada (def/n) y
    RD proyectada (ponderada por n). Columnas: q, pd_pit, pd_ttc, pd_ttc_adj, n, rd, rd_proj."""
    d = df_sub.copy()
    d['q'] = d['codmes'].astype(str).map(to_quarter)
    g = d.groupby('q').agg(
        pd_pit=('pd_pit', 'mean'),
        pd_ttc=('pd_ttc', 'mean'),
        pd_ttc_adj=('pd_ttc_adj', 'mean'),
        defaults=(TARGET_COL, 'sum'),
        n_t=(TARGET_COL, 'count'),
        n=('pd_pit', 'count'),
    ).reset_index().sort_values('q').reset_index(drop=True)
    g['rd'] = np.where(g['n_t'] > 0, g['defaults'] / g['n_t'], np.nan)
    g['rd_proj'] = np.nan
    if proj_list:
        acc = {}
        for p in proj_list:
            qq = to_quarter(p['codmes'])
            a = acc.setdefault(qq, [0.0, 0.0])
            a[0] += p['rd12_proj'] * p['n']
            a[1] += p['n']
        g['rd_proj'] = g['q'].map(lambda qq: acc[qq][0] / acc[qq][1]
                                  if qq in acc and acc[qq][1] > 0 else np.nan)
    return g


def set_paper_theme():
    """Tema monocromatico academico — replica PP reference."""
    for fam in ['STIXGeneral', 'DejaVu Serif', 'Times New Roman']:
        try:
            matplotlib.font_manager.findfont(fam, fallback_to_default=False)
            plt.rcParams['font.family'] = 'serif'
            plt.rcParams['font.serif'] = [fam]
            break
        except Exception:
            continue
    plt.rcParams.update({
        'axes.spines.top': False, 'axes.spines.right': False,
        'axes.edgecolor': MUTED, 'axes.linewidth': 0.6,
        'xtick.direction': 'in', 'ytick.direction': 'in',
        'xtick.major.size': 3, 'ytick.major.size': 3,
        'axes.grid': False,  # no grid by default (PP ref has none)
        'axes.facecolor': 'white', 'figure.facecolor': 'white',
        'savefig.dpi': 320, 'savefig.bbox': 'tight',
        'legend.frameon': False, 'legend.fontsize': 8,
        'axes.titlesize': 11, 'axes.labelsize': 9,
    })


set_paper_theme()
FIGSIZE = (9, 5)
FIGSIZE_WIDE = (11, 5.5)
FIGSIZE_TALL = (9, 7)
DPI = 320


def _has_negative(ax):
    """True si hay datos graficados por debajo de 0 (no forzar eje Y desde 0)."""
    for ln in ax.get_lines():
        yd = np.asarray(ln.get_ydata(), dtype=float)
        if yd.size and np.nanmin(yd) < -1e-9:
            return True
    for p in ax.patches:
        try:
            if p.get_height() < -1e-9 or p.get_y() < -1e-9:
                return True
        except Exception:
            pass
    return False


def save_chart(fig, name):
    """Finaliza y guarda PNG+PDF. Reglas paper aplicadas a cada eje:
    eje Y desde 0 (si no hay negativos), leyenda fuera del cuadro (derecha),
    etiquetas del eje X horizontales."""
    for ax in fig.axes:
        if ax.images:  # heatmap/imshow: no tocar
            continue
        if (ax.get_lines() or ax.patches) and not _has_negative(ax):
            ax.set_ylim(bottom=0)
        leg = ax.get_legend()
        if leg is not None:
            h, l = ax.get_legend_handles_labels()
            leg.remove()
            if h:
                ax.legend(h, l, loc='upper left', bbox_to_anchor=(1.01, 1.0),
                          fontsize=8, frameon=False, borderaxespad=0.3)
        xtl = ax.get_xticklabels()
        txts = [t for t in xtl if t.get_text()]
        if len(txts) > 12:  # adelgaza para que MMM-YY horizontal no se encime
            step = int(np.ceil(len(txts) / 9))
            for i, t in enumerate(txts):
                if i % step:
                    t.set_visible(False)
        for lbl in xtl:
            lbl.set_rotation(0)
            lbl.set_ha('center')
    fig.savefig(CHART_DIR / f'{name}.png', dpi=DPI, bbox_inches='tight')
    fig.savefig(CHART_DIR / f'{name}.pdf', bbox_inches='tight')
    plt.close(fig)
    print(f"  Chart: {name}")


_MESES_ABBR = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
               'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic']


def fmt_cm(codmes):
    """202401 -> 'Ene-24' (formato fecha MMM-YY)."""
    cm = str(codmes)
    return f"{_MESES_ABBR[int(cm[4:6]) - 1]}-{cm[2:4]}"


def fmt_year(codmes):
    """202401 → 2024"""
    return codmes[:4]


def open_marker(ax, x, y, marker='o', ms=5, color='black', label=None, lw=1.2, ls='-'):
    """Plot with open markers (PP reference style)."""
    return ax.plot(x, y, color=color, ls=ls, lw=lw, marker=marker, ms=ms,
                   markerfacecolor='white', markeredgecolor=color,
                   markeredgewidth=0.8, label=label)


# =============================================================================
# 1. CARGA DE DATOS
# =============================================================================

print("=" * 70)
print(f"  11 — CHARTS DOC METODOLOGICO {SUBPRODUCTO_FILTER}")
print("=" * 70)

df_full = pd.read_parquet(PATHS['parquets'] / 'full_calibrated.parquet')
df_full['codmes'] = df_full['codmes'].astype(str)

rd_mes = pd.read_csv(PATHS['csv'] / 'rd_mensual.csv')
rd_mes['codmes'] = rd_mes['codmes'].astype(str)

pit_mes = pd.read_csv(PATHS['csv'] / 'pit_mensual.csv')
pit_mes['codmes'] = pit_mes['codmes'].astype(str)

ft_cal = pd.read_csv(PATHS['csv'] / 'ft_calendario.csv')
ft_cal['codmes'] = ft_cal['codmes'].astype(str)

with open(PATHS['json'] / 'lra.json') as f:
    lra_json = json.load(f)
with open(PATHS['json'] / 'vasicek_rho.json') as f:
    rho_json = json.load(f)
with open(PATHS['json'] / 'macro_model.json') as f:
    macro_json = json.load(f)
with open(PATHS['json'] / 'pit_transformation.json') as f:
    pit_json = json.load(f)
with open(PATHS['json'] / 'monitoring.json') as f:
    mon_json = json.load(f)
with open(PATHS['json'] / 'rd_projections.json') as f:
    proj_json = json.load(f)
with open(PATHS['json'] / 'lambda_mle_binomial.json') as f:
    lam_json = json.load(f)
with open(PATHS['json'] / 'calibracion_beta.json') as f:
    cal_json = json.load(f)
# macro_selection_f1_f8.json lo produce analisis/macro_selection_f1_f8.py, que NO
# es parte de la cadena nucleo 00-11. Si no esta, se sigue sin el funnel en vez de
# abortar el paso entero: antes reventaba con FileNotFoundError y se perdian los
# 25 graficos por un insumo opcional.
_msel = PATHS['json'] / 'macro_selection_f1_f8.json'
if _msel.exists():
    with open(_msel, encoding='utf-8') as f:
        macro_sel_json = json.load(f)
else:
    macro_sel_json = {}
    print(f"  [aviso] {_msel.name} ausente: se omite el grafico del funnel macro. "
          f"Correr analisis/macro_selection_f1_f8.py si se lo necesita.")
with open(PATHS['json'] / 'pd_final.json') as f:
    pd_final_json = json.load(f)

pd_final_data = pd_final_json.get('driver_summary', [])

# RD12 proyectada (chain-ladder): solo las 6 proyecciones mas cercanas al cierre.
_proj_all = sorted(proj_json.get('global', {}).get('projections', []), key=lambda p: p['codmes'])
PROJ_MONTHS = [p['codmes'] for p in _proj_all][:6]
_proj_map = {p['codmes']: p['rd12_proj'] for p in _proj_all if p['codmes'] in PROJ_MONTHS}

lra_global = lra_json['lra_global']
rho = rho_json['rho_final']
sqrt_rho = np.sqrt(rho)
sqrt_1mrho = np.sqrt(1 - rho)

# Lambda MLE monthly data
monthly = lam_json.get('monthly', [])
if monthly:
    F_vals = np.array([m['F_capped'] for m in monthly])
    D_vals = np.array([m['defaults'] for m in monthly])
    N_vals = np.array([m['n'] for m in monthly])
    rd_obs_monthly = D_vals / N_vals

print(f"Datos cargados: {len(df_full):,} obs")
print("\n  Generando charts...")

# =============================================================================
# CHART 01 — RD12 observada mensual (PP ref: 02_rd_mensual_ibk.png)
# =============================================================================

fig, ax = plt.subplots(figsize=FIGSIZE)
rd_sorted = rd_mes.sort_values('codmes')
x = range(len(rd_sorted))
labels = rd_sorted['codmes'].values
mean_rd = rd_sorted[~rd_sorted['codmes'].isin(LRA_EXCL_MONTHS)]['rd'].mean()

plot_rd_hist(ax, list(x), rd_sorted['rd'] * 100, label='RD12 observada', ms=5)
ax.axhline(mean_rd * 100, color='black', ls='-.', lw=1.0,
           label=f'Media RD = {mean_rd*100:.2f}%')

tick_every = max(1, len(labels) // 10)
ax.set_xticks(range(0, len(labels), tick_every))
ax.set_xticklabels([fmt_cm(labels[i]) for i in range(0, len(labels), tick_every)],
                   rotation=45, ha='right', fontsize=7)

ax.set_ylabel('RD12 (%)')
ax.set_xlabel('')
ax.legend(loc='upper right', fontsize=8)
ax.set_title(f'IBK — RD12 observada mensual (flg_calib_rd)', fontsize=11)
save_chart(fig, '01_rd_mensual_ibk')

# =============================================================================
# CHART 02 — RD por Driver DEP/NO DEP (PP ref: 04_driver_ts)
# =============================================================================

fig, ax = plt.subplots(figsize=FIGSIZE)
seg_codmes = None
for i, seg in enumerate(SEG_VALUES):
    df_seg = df_full[df_full[SEG_COL] == seg].copy()
    rd_seg = df_seg.groupby('codmes')[TARGET_COL].mean().reset_index().sort_values('codmes')
    if seg_codmes is None:
        seg_codmes = rd_seg['codmes'].values
    line_smooth(ax, range(len(rd_seg)), rd_seg[TARGET_COL] * 100,
                color=CAT_COLORS[i], ls='-', lw=2.0, label=seg)
    lra_seg = lra_json['lra_by_segment'].get(seg, lra_global)
    ax.axhline(lra_seg * 100, color=CAT_COLORS[i], ls='--', lw=0.7, alpha=0.45)

tick_every = max(1, len(seg_codmes) // 10)
ax.set_xticks(range(0, len(seg_codmes), tick_every))
ax.set_xticklabels([fmt_cm(seg_codmes[i]) for i in range(0, len(seg_codmes), tick_every)])

ax.set_ylabel('RD12 (%)')
ax.set_xlabel('Mes')
ax.legend(loc='best', fontsize=8)
ax.set_title(f'IBK — RD12 por tipo_ingreso_dep', fontsize=11)
save_chart(fig, '02_rd_por_driver_dep')

# =============================================================================
# CHART 03 — RD por Driver tipo_ingreso_cs
# =============================================================================

fig, ax = plt.subplots(figsize=FIGSIZE)
cs_vals = sorted(df_full['tipo_ingreso_cs'].dropna().unique(), key=str)
cs_codmes = None
for i, val in enumerate(cs_vals):
    df_cs = df_full[df_full['tipo_ingreso_cs'] == val].copy()
    rd_cs = df_cs.groupby('codmes')[TARGET_COL].mean().reset_index().sort_values('codmes')
    if cs_codmes is None:
        cs_codmes = rd_cs['codmes'].values
    line_smooth(ax, range(len(rd_cs)), rd_cs[TARGET_COL] * 100,
                color=CAT_COLORS[i % len(CAT_COLORS)], ls='-', lw=2.0, label=val)

tick_every = max(1, len(cs_codmes) // 10)
ax.set_xticks(range(0, len(cs_codmes), tick_every))
ax.set_xticklabels([fmt_cm(cs_codmes[i]) for i in range(0, len(cs_codmes), tick_every)])
ax.set_ylabel('RD12 (%)')
ax.set_xlabel('Mes')
ax.legend(loc='best', fontsize=7)
ax.set_title(f'IBK — RD12 por tipo_ingreso_cs', fontsize=11)
save_chart(fig, '03_rd_por_driver_cs')

# =============================================================================
# CHART 04 — PD PIT vs RD mensual + semáforo (PP ref: 12_pit_vs_rd_IBK.png)
# =============================================================================

fig, ax = plt.subplots(figsize=FIGSIZE)
z1_pit = quarter_series(df_full, proj_json.get('global', {}).get('projections', []))
z1_pit = z1_pit.rename(columns={'pd_pit': 'pd_pit_mean', 'pd_ttc_adj': 'pd_ttc_mean'})
x = range(len(z1_pit))
xlabels = z1_pit['q'].values

# Banda IC Jeffreys 95% de la RD observada
_jlo, _jhi = jeffreys_band(z1_pit['rd'].values, z1_pit['n'].values, 0.025, 0.975)
ax.fill_between(list(x), _jlo * 100, _jhi * 100, color=BAND_BLUE, alpha=0.30, zorder=0, label='IC Jeffreys 95%')

# PD TTC: linea suavizada gris
if 'pd_ttc_mean' in z1_pit.columns:
    line_smooth(ax, list(x), z1_pit['pd_ttc_mean'] * 100, ls='--', lw=1.3, label='PD TTC')

# PD PIT: linea suavizada verde Interbank
plot_pit(ax, list(x), z1_pit['pd_pit_mean'] * 100, label='PD PIT')

# RD observada: marcador circular navy
plot_rd_hist(ax, list(x), z1_pit['rd'] * 100, label='RD12 observada', ms=6)

# RD proyectada (Z2): marcador circular rojo
_pm = z1_pit[z1_pit['rd_proj'].notna()]
if len(_pm):
    plot_rd_proj(ax, _pm.index.tolist(), _pm['rd_proj'] * 100, label='RD12 proyectada (Z2)', ms=6)
_bnd = z1_pit.index[z1_pit['q'] == to_quarter(COHORTE_FIN)]
if len(_bnd):
    ax.axvline(_bnd[0] + 0.5, color='black', ls='--', lw=0.5, alpha=0.5)

# LRA (dash-dot, PP ref style)
ax.axhline(lra_global * 100, color='black', ls='-.', lw=1,
           label=f'LRA={lra_global*100:.2f}%')

# Semaforo (EC x2 + Jeffreys): dots de color al tope
from monitoring import ec_status, jeffreys_pass, ec_relativo
ymax = max(z1_pit['rd'].max(), z1_pit['pd_pit_mean'].max()) * 100 * 1.15


def _sem_trim(row):
    """Semaforo de un trimestre: verde/amarillo/rojo (EC x2 + Jeffreys) o None."""
    rd_val, pd_val = row['rd'], row['pd_pit_mean']
    if pd_val <= 0 or np.isnan(rd_val):
        return None
    ec = ec_relativo(rd_val, pd_val)
    j = jeffreys_pass(row['defaults'], row['n_t'], pd_val)
    return ec_status(ec, bool(j) if j is not None else False)


_SEM_COL = {'verde': SEM_GREEN, 'amarillo': SEM_YELLOW, 'rojo': SEM_RED}
for i, (_, row) in enumerate(z1_pit.iterrows()):
    st = _sem_trim(row)
    if st:
        ax.plot(i, ymax, 'o', color=_SEM_COL.get(st, MUTED), ms=5, zorder=5)

ax.set_ylim(top=ymax * 1.08)

# X ticks (trimestral)
ax.set_xticks(list(x))
ax.set_xticklabels([fmt_q(q) for q in xlabels], fontsize=8)

# Conteo semáforo (EC x2 + Jeffreys)
_sem_all = [_sem_trim(r) for _, r in z1_pit.iterrows()]
n_v = _sem_all.count('verde')
n_a = _sem_all.count('amarillo')
n_r = _sem_all.count('rojo')

gini_pit = mon_json.get('gini_pit', 0)
ax.set_ylabel('Tasa (%)')
ax.set_xlabel('Mes')
ax.legend(loc='upper right', fontsize=7)
ax.set_title(f'IBK — PD PIT vs RD Trimestral ({n_v}V/{n_a}A/{n_r}R, Gini={gini_pit:.4f})',
             fontsize=11)
save_chart(fig, '04_pit_vs_rd_ibk')

# =============================================================================
# CHART 05 — Cadena de calibración PD raw → TTC → PIT
# =============================================================================

fig, ax = plt.subplots(figsize=FIGSIZE)
agg = df_full.groupby('codmes').agg(
    rd=(TARGET_COL, 'mean'),
    pd_ree=(SCORE_COL, 'mean'),
    pd_ttc=('pd_ttc', 'mean'),
    pd_pit=('pd_pit', 'mean'),
    n=('pd_pit', 'count'),
).reset_index().sort_values('codmes').reset_index(drop=True)
agg['rd_proj'] = agg['codmes'].map(_proj_map)

x = range(len(agg))
xlabels = agg['codmes'].values

# Banda IC Jeffreys 95% de la RD observada
_jlo, _jhi = jeffreys_band(agg['rd'].values, agg['n'].values, 0.025, 0.975)
ax.fill_between(list(x), _jlo * 100, _jhi * 100, color=BAND_BLUE, alpha=0.28, zorder=0, label='IC Jeffreys 95%')

# PD raw / TTC: lineas suavizadas grises
line_smooth(ax, list(x), agg['pd_ree'] * 100, color=RAW_GRAY, ls=':', lw=1.2, label='PD raw')
line_smooth(ax, list(x), agg['pd_ttc'] * 100, color=TTC_GRAY, ls='--', lw=1.3, label='PD TTC')

# PD PIT: linea suavizada verde Interbank
plot_pit(ax, list(x), agg['pd_pit'] * 100, label='PD PIT')

# RD observada: marcador circular navy
plot_rd_hist(ax, list(x), agg['rd'] * 100, label='RD12 observada', ms=6)

# RD proyectada (Z2): marcador circular rojo
_pm = agg[agg['rd_proj'].notna()]
if len(_pm):
    plot_rd_proj(ax, _pm.index.tolist(), _pm['rd_proj'] * 100, label='RD12 proyectada (Z2)', ms=6)
_bnd = agg.index[agg['codmes'] == COHORTE_FIN]
if len(_bnd):
    ax.axvline(_bnd[0] + 0.5, color='black', ls='--', lw=0.5, alpha=0.5)

ax.axhline(lra_global * 100, color='black', ls='-.', lw=1,
           label=f'LRA={lra_global*100:.2f}%')

tick_every = max(1, len(xlabels) // 10)
ax.set_xticks(range(0, len(xlabels), tick_every))
ax.set_xticklabels([fmt_cm(xlabels[i]) for i in range(0, len(xlabels), tick_every)],
                    rotation=45, ha='right', fontsize=7)
ax.set_ylabel('PD / RD (%)')
ax.set_xlabel('Mes')
ax.legend(fontsize=7, ncol=2, loc='upper right')
ax.set_title(f'IBK — Cadena de calibracion: PD raw → TTC → PIT', fontsize=11)
save_chart(fig, '05_cadena_pd_calibracion')

# =============================================================================
# CHART 06 — RD + PIT + Proyecciones Z2 (PP ref: 15_backtesting_GLOBAL.png)
# =============================================================================

fig, ax = plt.subplots(figsize=FIGSIZE_WIDE)

z1_data = pit_mes.sort_values('codmes')
n_z1 = len(z1_data)

# Z1: Vasicek bands
z1_pd_pit = z1_data['pd_pit_mean'].values
z1_rd = z1_data['rd'].values

# Compute Vasicek q10/q90 bands
x_z1 = range(n_z1)
# Banda IC Jeffreys 95% (q2.5/q97.5) de la RD observada
z1_n = z1_data['n'].values if 'n' in z1_data.columns else np.full(n_z1, 1000)
jlo, jhi = jeffreys_band(z1_rd, z1_n, 0.025, 0.975)
ax.fill_between(x_z1, jlo * 100, jhi * 100, color=BAND_BLUE, alpha=0.4, label='IC Jeffreys 95%')

# PD TTC: linea suavizada gris
ttc_z1 = (z1_data['pd_ttc_mean'].values if 'pd_ttc_mean' in z1_data.columns else z1_pd_pit) * 100
line_smooth(ax, list(x_z1), ttc_z1, ls='--', lw=1.3, label='PD TTC')
# PD PIT Z1: linea suavizada verde Interbank
plot_pit(ax, list(x_z1), z1_pd_pit * 100, label='PD PIT')
# RD observada (cerrado): marcador circular navy
plot_rd_hist(ax, list(x_z1), z1_rd * 100, label='RD12 observada', ms=6)

# Z2 Projections
projs = [p for p in proj_json['global']['projections'] if p['codmes'] in PROJ_MONTHS]
if projs:
    proj_x = list(range(n_z1, n_z1 + len(projs)))
    proj_rd = [p['rd12_proj'] * 100 for p in projs]
    plot_rd_proj(ax, proj_x, proj_rd, label='RD12 proyectada (Z2)', ms=7)

    # PD PIT Z2: continua la linea verde suavizada
    df_z2 = df_full[df_full['codmes'] > COHORTE_FIN].copy()
    z2_agg = df_z2.groupby('codmes')['pd_pit'].mean().reset_index().sort_values('codmes')
    if len(z2_agg) > 0:
        z2_x = list(range(n_z1, n_z1 + len(z2_agg)))
        plot_pit(ax, z2_x, z2_agg['pd_pit'] * 100, label='PD PIT (Z2)')

# LRA + Z1/Z2 boundary
ax.axhline(lra_global * 100, color='black', ls='-.', lw=1)
ax.axvline(n_z1 - 0.5, color='black', ls='--', lw=0.5, alpha=0.5)
ax.text(n_z1 + 0.2, ax.get_ylim()[1] * 0.97, 'Z2', fontsize=8, ha='left')
ax.text(n_z1 - 1.5, ax.get_ylim()[1] * 0.97, 'Z1', fontsize=8, ha='right')

# X labels
all_cm = list(z1_data['codmes'].values) + ([p['codmes'] for p in projs] if projs else [])
tick_every = max(1, len(all_cm) // 14)
ax.set_xticks(range(0, len(all_cm), tick_every))
ax.set_xticklabels([fmt_cm(all_cm[i]) for i in range(0, len(all_cm), tick_every)],
                    rotation=45, ha='right', fontsize=7)
ax.set_ylabel('PD / RD (%)')
ax.set_xlabel('Mes')
ax.legend(fontsize=7, ncol=3, loc='upper right')
ax.set_title(f'IBK Z1 Backtesting GLOBAL | Vasicek q10/q90', fontsize=11)
save_chart(fig, '06_backtesting_global')

# =============================================================================
# CHART 07 — EC relativo mensual (PP ref: 12_ec_pit_lag_diagnostic 2nd panel)
# =============================================================================

fig, (ax1, ax2) = plt.subplots(2, 1, figsize=FIGSIZE_TALL, height_ratios=[1.3, 1],
                                sharex=True, gridspec_kw={'hspace': 0.15})

# Top: PIT vs RD with bands (PD hasta 202603, RD obs Z1 + RD proyectada Z2)
ec_data = df_full.groupby('codmes').agg(
    pd_pit_mean=('pd_pit', 'mean'), rd=(TARGET_COL, 'mean'), n=('pd_pit', 'count'),
).reset_index().sort_values('codmes').reset_index(drop=True)
ec_data['rd_proj'] = ec_data['codmes'].map(_proj_map)
ec_data['ec'] = (ec_data['rd'] - ec_data['pd_pit_mean']) / ec_data['pd_pit_mean']
x = range(len(ec_data))

# ±25% RD dashed bands
_jlo, _jhi = jeffreys_band(ec_data['rd'].values, ec_data['n'].values, 0.025, 0.975)
ax1.fill_between(list(x), _jlo * 100, _jhi * 100, color=BAND_BLUE, alpha=0.45, label='IC Jeffreys 95%')
plot_pit(ax1, list(x), ec_data['pd_pit_mean'] * 100, label='PD PIT')
plot_rd_hist(ax1, list(x), ec_data['rd'] * 100, label='RD12 observada', ms=6)
_pm = ec_data[ec_data['rd_proj'].notna()]
if len(_pm):
    plot_rd_proj(ax1, _pm.index.tolist(), _pm['rd_proj'] * 100, label='RD12 proyectada (Z2)', ms=6)
ax1.axhline(lra_global * 100, color='black', ls='-.', lw=0.8)
ax1.set_ylabel('Tasa (%)')
ax1.legend(fontsize=7, ncol=3, loc='upper right')
ax1.set_title(f'IBK — PD PIT vs RD12 | IC Jeffreys 95%', fontsize=11)

# Bottom: EC bars with hatch differentiation Z1/Z2
for i, (_, row) in enumerate(ec_data.iterrows()):
    ec_val = row['ec'] * 100
    if np.isnan(ec_val):
        continue
    c = RD_RED if ec_val >= 0 else NAVY
    ax2.bar(i, ec_val, width=0.8, facecolor=c, edgecolor='white', linewidth=0.3)

ax2.axhline(0, color='black', lw=0.8)
ax2.axhline(-15, color=MUTED, ls='--', lw=0.5, alpha=0.5)
ax2.axhline(+10, color=MUTED, ls='--', lw=0.5, alpha=0.5)
ax2.axhline(-30, color=MUTED, ls=':', lw=0.5, alpha=0.5)
ax2.axhline(+20, color=MUTED, ls=':', lw=0.5, alpha=0.5)

ax2.set_ylabel('EC PIT (%)')
ax2.set_xlabel('Mes')

# Count buenos
n_buenos = sum(1 for _, r in ec_data.iterrows() if abs(r['ec']) <= 0.15)
n_total = int(ec_data['ec'].notna().sum())
ax2.set_title(f'Error de Calibracion PIT (PD_PIT - RD) / RD × 100  |  '
              f'Dentro ±15%: {n_buenos}/{n_total}', fontsize=9)

tick_labels = ec_data['codmes'].values
tick_every = max(1, len(tick_labels) // 12)
ax2.set_xticks(range(0, len(tick_labels), tick_every))
ax2.set_xticklabels([fmt_cm(tick_labels[i]) for i in range(0, len(tick_labels), tick_every)],
                     rotation=45, ha='right', fontsize=7)

save_chart(fig, '07_ec_pit_diagnostic')

# =============================================================================
# CHART 08 — ft calendario (PP ref: 11_ft_calendario.png — HATCHED bars)
# =============================================================================

fig, ax = plt.subplots(figsize=FIGSIZE)
ft_plot = ft_cal.sort_values('codmes').copy()
x = range(len(ft_plot))
ft_vals = ft_plot['ft_GLOBAL'].values
cm_vals = ft_plot['codmes'].values

# Hatched bars (positive = fitted hatch, different for Z1 vs Z2-like)
for i, (fv, cm) in enumerate(zip(ft_vals, cm_vals)):
    in_z1 = cm <= COHORTE_FIN
    hatch = '////' if in_z1 else 'xxxx'
    ax.bar(i, fv, width=1.0, facecolor='white', edgecolor='black',
           hatch=hatch, linewidth=0.3)

# Data points as open circles
open_marker(ax, x, ft_vals, marker='o', ms=3, lw=0, color='black')

ax.axhline(0, color='black', ls='-', lw=0.5)

# Z1/Z2 boundary
z1_end = [i for i, cm in enumerate(cm_vals) if cm == COHORTE_FIN]
if z1_end:
    ax.axvline(z1_end[0] + 0.5, color='black', ls='--', lw=0.5, alpha=0.5)

# Legend
n_fit = sum(1 for cm in cm_vals if cm <= COHORTE_FIN)
n_oos = len(cm_vals) - n_fit
handles = [Patch(facecolor='white', edgecolor='black', hatch='////',
                 label=f'Probit fitted (n={n_fit})'),
           Patch(facecolor='white', edgecolor='black', hatch='xxxx',
                 label=f'Probit OOS (n={n_oos})')]
ax.legend(handles=handles, loc='upper right', fontsize=8)

# Year ticks
year_pos = [i for i, cm in enumerate(cm_vals) if cm[4:6] == '01']
ax.set_xticks(year_pos)
ax.set_xticklabels([cm_vals[i][:4] for i in year_pos])
ax.set_ylabel('ft (factor calendario)')
ax.set_xlabel('')
ax.set_title(f'ft calendario — Probit IBK {SUBPRODUCTO_FILTER} '
             f'({macro_json["champion_variables"][0]})', fontsize=11)
save_chart(fig, '08_ft_calendario')

# =============================================================================
# CHART 09 — Reliability diagram (BIAS vs VARIANCE — PP ref: 03_reliability)
# =============================================================================

fig, ax = plt.subplots(figsize=(7, 7))
df_z1_rel = df_full[(df_full['codmes'] <= COHORTE_FIN) &
                     (df_full[TARGET_COL].notna())].copy()

# Deciles of PD PIT
df_z1_rel['decile'] = pd.qcut(df_z1_rel['pd_pit'], 10, labels=False, duplicates='drop')
rel = df_z1_rel.groupby('decile').agg(
    pd_mean=('pd_pit', 'mean'),
    rd_obs=(TARGET_COL, 'mean'),
    n=('pd_pit', 'count'),
).reset_index()

# Perfect calibration line (gray dashed)
ax.plot([0, rel['pd_mean'].max() * 1.1 * 100], [0, rel['pd_mean'].max() * 1.1 * 100],
        color=LIGHT, ls='--', lw=1, zorder=1)
ax.plot(rel['pd_mean'].max() * 1.1 * 100, rel['pd_mean'].max() * 1.1 * 100,
        'o', color=LIGHT, ms=6, markeredgecolor=LIGHT, zorder=1,
        label='Perfecta calibracion')

# Data points (black filled circles with n labels)
ax.scatter(rel['pd_mean'] * 100, rel['rd_obs'] * 100, color='black', s=50, zorder=3)
for _, row in rel.iterrows():
    ax.annotate(f"n={int(row['n']):,}", (row['pd_mean'] * 100, row['rd_obs'] * 100),
                textcoords="offset points", xytext=(5, 5), fontsize=7, color=MUTED)

ax.set_xlabel('PD media (pd_pit)')
ax.set_ylabel('RD observada')
ax.set_aspect('equal')
ax.legend(loc='upper left', fontsize=8)
ax.set_title(f'IBK Z1 — Reliability diagram (pd_pit)', fontsize=11)
save_chart(fig, '09_reliability_ibk')

# =============================================================================
# CHART 10 — Funnel F1-F8 (PP ref: 06c_funnel_f1_f8.png — horizontal bars)
# =============================================================================

fig, ax = plt.subplots(figsize=FIGSIZE)
funnel = macro_sel_json.get('funnel', {})
if funnel:
    labels_f = ['Total', 'F1\nRelevancia', 'F2\nDisponib.', 'F3\nCorr+signo',
                'F4\nGranger', 'F5\nCointeg.', 'F6\nBuenos/Malos', 'F7\nRobustez',
                'F8\nRégimen']
    keys_f = ['total', 'F1_relevancia', 'F2_disponibilidad', 'F3_correlacion_signo',
              'F4_granger', 'F5_cointegracion', 'F6_buenos_malos', 'F7_robustez', 'F8_regimen']
    vals_f = [funnel.get(k, 0) for k in keys_f]

    y_pos = range(len(vals_f) - 1, -1, -1)
    ax.barh(y_pos, vals_f, height=0.7, facecolor='white', edgecolor='black',
            linewidth=0.5)

    for i, (yp, v) in enumerate(zip(y_pos, vals_f)):
        ax.text(v + max(vals_f) * 0.01, yp, f'{v:,}', va='center', fontsize=8)

    ax.set_yticks(list(y_pos))
    ax.set_yticklabels(labels_f)
    ax.set_xlabel('Variables')
    ax.set_title(f'Funnel de seleccion macro F1-F8', fontsize=11)

save_chart(fig, '10_funnel_f1_f8')

# =============================================================================
# CHART 11 — Macro: RD vs fitted + residuales (PP ref: 11_fitted_vs_observed)
# =============================================================================

fig, (ax1, ax2) = plt.subplots(2, 1, figsize=FIGSIZE_TALL, height_ratios=[1.2, 1],
                                sharex=True, gridspec_kw={'hspace': 0.12})

rd_fit = rd_mes.merge(ft_cal[['codmes', 'ft_GLOBAL']], on='codmes', how='inner')
rd_fit = rd_fit[~rd_fit['codmes'].isin(COVID_EXCL_MONTHS)].sort_values('codmes')
rd_fit['rd_fitted'] = norm.cdf(rd_fit['ft_GLOBAL'])

x = range(len(rd_fit))
xlabels = rd_fit['codmes'].values

# Top: obs vs fitted
line_smooth(ax1, list(x), rd_fit['rd_fitted'] * 100, color=TTC_GRAY, ls='--', lw=1.3, label='RD ajustada')
plot_rd_hist(ax1, list(x), rd_fit['rd'] * 100, label='RD12 observada', ms=5)
ax1.axhline(lra_global * 100, color='black', ls='-.', lw=0.8)
ax1.set_ylabel('RD12 (%)')
ax1.legend(fontsize=7, loc='upper right')
ax1.set_title(f'IBK — Modelo Macro PROBIT: Observed vs Fitted', fontsize=11)

# Bottom: residuals (hatched bars)
resid = (rd_fit['rd'] - rd_fit['rd_fitted']) * 10000
for i, r in enumerate(resid):
    hatch = '////' if r >= 0 else '....'
    ax2.bar(i, r, width=0.8, facecolor='white', edgecolor='black',
            hatch=hatch, linewidth=0.4)
ax2.axhline(0, color='black', lw=0.8)
ax2.set_ylabel('Residual (bps)')
ax2.set_xlabel('Mes')
ax2.set_title(f'Residuales macro (MAE={abs(resid).mean():.0f}bps)', fontsize=9)

tick_every = max(1, len(xlabels) // 10)
ax2.set_xticks(range(0, len(xlabels), tick_every))
ax2.set_xticklabels([fmt_cm(xlabels[i]) for i in range(0, len(xlabels), tick_every)])

save_chart(fig, '11_macro_fitted_vs_observed')

# =============================================================================
# CHART 12 — Monitoring heatmap (PP ref: 18_monitoring_heatmap.png)
# =============================================================================

fig, ax = plt.subplots(figsize=(14, 3.5))
# Build EC × segment × month matrix
segments_hm = ['GLOBAL'] + SEG_VALUES
z1_months = sorted(pit_mes['codmes'].unique())

for seg_idx, seg_name in enumerate(segments_hm):
    for m_idx, cm in enumerate(z1_months):
        if seg_name == 'GLOBAL':
            sub = pit_mes[pit_mes['codmes'] == cm]
            if len(sub) == 0:
                continue
            rd_v = sub['rd'].values[0]
            pd_v = sub['pd_pit_mean'].values[0]
            k_v, n_v = float(sub['defaults'].values[0]), float(sub['n'].values[0])
        else:
            sub = df_full[(df_full['codmes'] == cm) & (df_full[SEG_COL] == seg_name) &
                          (df_full['codmes'] <= COHORTE_FIN)]
            if len(sub) == 0:
                continue
            rd_v = sub[TARGET_COL].mean()
            pd_v = sub['pd_pit'].mean()
            k_v, n_v = float(sub[TARGET_COL].sum()), float(sub[TARGET_COL].count())

        if pd_v > 0 and not np.isnan(rd_v):
            ec = ec_relativo(rd_v, pd_v)             # (RD-PD)/PD canonico
            j = jeffreys_pass(k_v, n_v, pd_v)
            st = ec_status(ec, bool(j) if j is not None else False)

            # Color por semaforo (EC x2 + Jeffreys), intensidad por magnitud del EC
            alpha_val = min(abs(ec) / 0.6, 1.0) * 0.55 + 0.18
            rect = plt.Rectangle((m_idx - 0.4, seg_idx - 0.35), 0.8, 0.7,
                                  facecolor=_SEM_COL.get(st, MUTED), edgecolor='white',
                                  linewidth=0.3, alpha=alpha_val)
            ax.add_patch(rect)
            ax.text(m_idx, seg_idx, f'{ec:+.2f}', ha='center', va='center',
                    fontsize=6, color='black')

ax.set_xlim(-0.5, len(z1_months) - 0.5)
ax.set_ylim(-0.5, len(segments_hm) - 0.5)
ax.set_yticks(range(len(segments_hm)))
ax.set_yticklabels(segments_hm, fontsize=8)
ax.set_xticks(range(len(z1_months)))
ax.set_xticklabels([fmt_cm(cm) for cm in z1_months], rotation=45, ha='right', fontsize=6)
ax.set_title('Semáforo mensual — EC ×2 + Jeffreys (mes × segmento)', fontsize=11)
ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)
save_chart(fig, '12_monitoring_heatmap')

# =============================================================================
# CHART 13 — Sensibilidad LRA (PP ref: 09_lra_sensitivity.png — hatched bars)
# =============================================================================

fig, ax = plt.subplots(figsize=FIGSIZE)
# LRA by rolling start year
rd_all = rd_mes.sort_values('codmes').copy()
start_years = sorted(set(cm[:4] for cm in rd_all['codmes']))
lra_by_start = []
for yr in start_years:
    sub = rd_all[(rd_all['codmes'] >= f'{yr}01') &
                 (~rd_all['codmes'].isin(LRA_EXCL_MONTHS))]
    if len(sub) > 6:
        lra_by_start.append({'year': yr, 'lra': sub['rd'].median() * 100})

if lra_by_start:
    df_lra_s = pd.DataFrame(lra_by_start)
    ax.bar(range(len(df_lra_s)), df_lra_s['lra'], width=0.7,
           facecolor='white', edgecolor='black', hatch='////', linewidth=0.5)
    ax.axhline(lra_global * 100, color='black', ls='-.', lw=1.2,
               label=f'LRA full = {lra_global*100:.2f}%')
    ax.set_xticks(range(len(df_lra_s)))
    ax.set_xticklabels(df_lra_s['year'])
    ax.set_ylabel('LRA (%)')
    ax.set_ylim(bottom=0)
    ax.legend(loc='upper right', fontsize=8)
    ax.set_title(f'IBK — Sensibilidad LRA por ventana inicial', fontsize=11)

save_chart(fig, '13_lra_sensitivity')

# =============================================================================
# CHART 14 — Sensibilidad lambda (MAE curve)
# =============================================================================

fig, ax = plt.subplots(figsize=FIGSIZE)
lam_grid = np.linspace(0.01, 1.5, 100)

if monthly:
    mae_by_lam = []
    for lam in lam_grid:
        pd_pit = norm.cdf((norm.ppf(lra_global) - sqrt_rho * lam * F_vals) / sqrt_1mrho)
        mae = np.mean(np.abs(rd_obs_monthly - pd_pit)) * 10000
        mae_by_lam.append(mae)

    ax.plot(lam_grid, mae_by_lam, 'k-', lw=1.3)
    ax.axvline(LAMBDA_PIT, color='black', ls='--', lw=1,
               label=f'λ={LAMBDA_PIT} (config)')
    lam_mle = lam_json.get('lambda_mle', LAMBDA_PIT)
    ax.axvline(lam_mle, color=MUTED, ls=':', lw=1,
               label=f'λ MLE={lam_mle:.3f}')
    ax.axvline(1.0, color=MUTED, ls='-.', lw=0.8,
               label='λ=1.0 (full PIT)')

ax.set_xlabel('λ (partial adjustment)')
ax.set_ylabel('MAE (bps)')
ax.legend(fontsize=8)
ax.set_title(f'IBK — Sensibilidad a λ', fontsize=11)
save_chart(fig, '14_sensibilidad_lambda')

# =============================================================================
# CHART 15 — Profile Log-Likelihood lambda
# =============================================================================

fig, ax = plt.subplots(figsize=FIGSIZE)
ll_grid = lam_json.get('profile_ll', {})
if ll_grid:
    lam_x = ll_grid['lambda_grid']
    ll_y = ll_grid['ll_grid']
    ll_max = max(ll_y)
    ll_norm = [l - ll_max for l in ll_y]

    ax.plot(lam_x, ll_norm, 'k-', lw=1.3)
    ax.axhline(-1.92, color=MUTED, ls='--', lw=0.7,
               label='95% CI (χ²₁/2=1.92)')
    ax.axvline(LAMBDA_PIT, color='black', ls='--', lw=1,
               label=f'λ={LAMBDA_PIT}')
    ax.axvline(1.0, color=MUTED, ls=':', lw=0.8, label='λ=1.0')
    ax.set_ylim(bottom=min(-10, min(ll_norm) * 1.1))

ax.set_xlabel('λ')
ax.set_ylabel('ΔLL (vs MLE)')
ax.legend(fontsize=8)
ax.set_title(f'IBK — Profile Log-Likelihood λ', fontsize=11)
save_chart(fig, '15_profile_ll_lambda')

# =============================================================================
# CHART 16 — Sensibilidad rho
# =============================================================================

fig, ax = plt.subplots(figsize=FIGSIZE)
rho_grid = np.linspace(0.005, 0.10, 50)

if monthly:
    mae_by_rho = []
    for rho_s in rho_grid:
        sq_r = np.sqrt(rho_s)
        sq_1mr = np.sqrt(1 - rho_s)
        pd_pit = norm.cdf((norm.ppf(lra_global) - sq_r * LAMBDA_PIT * F_vals) / sq_1mr)
        mae = np.mean(np.abs(rd_obs_monthly - pd_pit)) * 10000
        mae_by_rho.append(mae)

    ax.plot(rho_grid, mae_by_rho, 'k-', lw=1.3)
    ax.axvline(rho, color='black', ls='--', lw=1, label=f'ρ={rho:.4f} (MoM)')
    ax.axvline(RHO_FLOOR, color=MUTED, ls=':', lw=0.8,
               label=f'ρ floor={RHO_FLOOR}')

ax.set_xlabel('ρ (asset correlation)')
ax.set_ylabel('MAE (bps)')
ax.legend(fontsize=8)
ax.set_title(f'IBK — Sensibilidad a ρ', fontsize=11)
save_chart(fig, '16_sensibilidad_rho')

# =============================================================================
# CHART 17 — Stress scenarios (PP ref: 16_stress_scenarios.png — hatched bars)
# =============================================================================

fig, ax = plt.subplots(figsize=FIGSIZE)

# Escenarios: base (f=0), adverso (f=P10), severo (f=P01).
# CORREGIDO 2026-07-27: estaban en P90/P99, o sea del lado BENIGNO. Medido
# corr(F, RD_obs) = -0.80: F ALTO = ciclo benigno = PD BAJA. Con P90/P99 el
# 'adverso' daba PD 2.800% contra 3.931% de la base -- el escenario de estres
# salia MENOS riesgoso que el base, y ademas P90 y P99 coincidian por estar los
# dos topados en el cap superior. Los percentiles de estres son los BAJOS.
f_base = 0.0
f_adverso = np.percentile(F_vals, 10) if monthly else -1.0
f_severo = np.percentile(F_vals, 1) if monthly else -2.0

scenarios = [('base', f_base), ('adverso', f_adverso), ('severo', f_severo)]
bar_width = 0.35
x_pos = np.arange(len(scenarios))

for idx, (name, f_val) in enumerate(scenarios):
    pd_pit = norm.cdf((norm.ppf(lra_global) - sqrt_rho * LAMBDA_PIT * f_val) / sqrt_1mrho)
    rd_pred = norm.cdf(norm.ppf(lra_global) + sqrt_rho * f_val)  # RD at this macro state

    ax.bar(idx - bar_width / 2, pd_pit * 100, bar_width, facecolor='white',
           edgecolor='black', hatch='////', linewidth=0.5)
    ax.bar(idx + bar_width / 2, rd_pred * 100, bar_width, facecolor='white',
           edgecolor='black', hatch='....', linewidth=0.5)

handles = [Patch(facecolor='white', edgecolor='black', hatch='////', label='PD PIT (median)'),
           Patch(facecolor='white', edgecolor='black', hatch='....', label='RD predicted')]
ax.legend(handles=handles, fontsize=8)
ax.set_xticks(x_pos)
ax.set_xticklabels([s[0] for s in scenarios])
ax.set_ylabel('PD / RD (%)')
ax.set_title(f'Stress testing — PD PIT por escenario', fontsize=11)
save_chart(fig, '17_stress_scenarios')

# =============================================================================
# CHART 18 — Distribución PD raw vs PIT (density overlay)
# =============================================================================

fig, ax = plt.subplots(figsize=FIGSIZE)
df_z1_h = df_full[df_full['codmes'] <= COHORTE_FIN].copy()

bins = np.linspace(0, 0.15, 40) * 100
ax.hist(df_z1_h[SCORE_COL] * 100, bins=bins, facecolor='white',
        edgecolor=RAW_GRAY, hatch='////', linewidth=0.5, density=True, label='PD raw')
ax.hist(df_z1_h['pd_pit'] * 100, bins=bins,
        edgecolor=IBK_GREEN, lw=1.8, histtype='step', density=True, label='PD PIT')
ax.axvline(lra_global * 100, color='black', ls='-.', lw=1,
           label=f'LRA={lra_global*100:.2f}%')

ax.set_xlabel('PD (%)')
ax.set_ylabel('Densidad')
ax.legend(fontsize=8)
ax.set_title(f'IBK — Distribucion PD raw vs PIT (Z1)', fontsize=11)
save_chart(fig, '18_distribucion_pd_raw_vs_pit')

# =============================================================================
# CHART 19 — Stress curves: PD PIT bajo distintos F
# =============================================================================

fig, ax = plt.subplots(figsize=FIGSIZE)
f_scenarios = np.linspace(-2, 2, 100)
pd_ttc_levels = [0.02, 0.035, lra_global, 0.06, 0.08]
lstyles = [':', '--', '-', '--', ':']
lwidths = [0.8, 0.8, 1.5, 0.8, 0.8]

for i, pd_ttc in enumerate(pd_ttc_levels):
    pd_pit_curve = norm.cdf(
        (norm.ppf(pd_ttc) - sqrt_rho * LAMBDA_PIT * f_scenarios) / sqrt_1mrho
    )
    lbl = f'TTC={pd_ttc*100:.1f}%'
    ax.plot(f_scenarios, pd_pit_curve * 100, color='black',
            lw=lwidths[i], ls=lstyles[i], label=lbl)

ax.axvline(0, color=MUTED, ls=':', lw=0.5)
ax.set_xlabel('F (systematic factor)')
ax.set_ylabel('PD PIT (%)')
ax.legend(fontsize=7, title='PD TTC levels', title_fontsize=7)
ax.set_title(f'IBK — Stress: PD PIT bajo distintos estados macro', fontsize=11)
save_chart(fig, '19_stress_macro_curves')

# =============================================================================
# CHART 20 — Sensitivity backtest (PP ref: 12b_sensitivity_backtest.png)
# Two panels: top = PIT vs RD with TRAIN/OOT split, bottom = EC bars
# =============================================================================

fig, (ax1, ax2) = plt.subplots(2, 1, figsize=FIGSIZE_TALL, height_ratios=[1.3, 1],
                                sharex=True, gridspec_kw={'hspace': 0.12})

z1_sorted = pit_mes.sort_values('codmes').copy()
n_train = int(len(z1_sorted) * 0.7)  # ~70% train
n_total = len(z1_sorted)

x_all = range(n_total)
xlabels = z1_sorted['codmes'].values

# Top panel: PIT train (solid) + PIT OOT (dashed+squares)
plot_rd_hist(ax1, range(n_total), z1_sorted['rd'].values * 100, label='RD12 observada', ms=5)

# PD PIT: linea continua suavizada (train+OOT); la region OOT se sombrea aparte
plot_pit(ax1, range(n_total), z1_sorted['pd_pit_mean'].values * 100, label='PD PIT')

if 'pd_ttc_mean' in z1_sorted.columns:
    line_smooth(ax1, x_all, z1_sorted['pd_ttc_mean'] * 100, color=RAW_GRAY, ls='-', lw=1.0, label='TTC')

# OOT region shading
ax1.axvspan(n_train - 0.5, n_total - 0.5, alpha=0.06, color='black')
ax1.set_ylabel('RD / PD (%)')
ax1.legend(fontsize=7, ncol=2, loc='upper right')

cutoff_cm = xlabels[n_train] if n_train < len(xlabels) else '?'
ax1.set_title(f'Sensitivity: Cadena reentrenada hasta {fmt_cm(xlabels[n_train-1])}, '
              f'OOT={fmt_cm(cutoff_cm)}-{fmt_cm(xlabels[-1])}', fontsize=10)

# Bottom panel: EC bars with TRAIN/OOT hatch distinction
ec_vals = ((z1_sorted['pd_pit_mean'] - z1_sorted['rd']) / z1_sorted['rd'] * 100).values

for i, ec in enumerate(ec_vals):
    c = NAVY if i < n_train else '#E08A1E'
    ax2.bar(i, ec, width=0.8, facecolor=c, edgecolor='white', linewidth=0.3)

ax2.axhline(0, color='black', lw=0.8)
# ±25% RD bands
ax2.axhline(25, color=MUTED, ls=':', lw=0.5)
ax2.axhline(-25, color=MUTED, ls=':', lw=0.5)

handles = [Patch(facecolor=NAVY, label='TRAIN'),
           Patch(facecolor='#E08A1E', label='OOT')]
ax2.legend(handles=handles, fontsize=7, loc='lower left')
ax2.set_ylabel('EC = PIT - RD (pp)')
ax2.set_xlabel('Mes')
ax2.set_title(f'Error de calibracion por mes (±25%RD dashed)', fontsize=9)

tick_every = max(1, len(xlabels) // 10)
ax2.set_xticks(range(0, len(xlabels), tick_every))
ax2.set_xticklabels([fmt_cm(xlabels[i]) for i in range(0, len(xlabels), tick_every)],
                     rotation=45, ha='right', fontsize=7)

save_chart(fig, '20_sensitivity_backtest')

# =============================================================================
# CHART 21 — RD vs Macro overlay (dual axis, PP style)
# =============================================================================

fig, ax1 = plt.subplots(figsize=FIGSIZE_WIDE)
rd_sorted = rd_mes.sort_values('codmes')
x = range(len(rd_sorted))
labels = rd_sorted['codmes'].values

# RD observada: marcador circular navy
plot_rd_hist(ax1, list(x), rd_sorted['rd'] * 100, label='RD12 observada', ms=5)
ax1.axhline(lra_global * 100, color='black', ls='-.', lw=1,
            label=f'LRA={lra_global*100:.2f}%')

# COVID shading
covid_idx = [i for i, cm in enumerate(labels) if cm in COVID_EXCL_MONTHS]
if covid_idx:
    ax1.axvspan(min(covid_idx) - 0.5, max(covid_idx) + 0.5,
                alpha=0.08, color='black', label='COVID excl')

ax1.set_ylabel('RD12 (%)')
ax1.set_xlabel('Mes')

# Macro on secondary axis
ft_merged = rd_sorted.merge(ft_cal[['codmes', 'ft_GLOBAL']], on='codmes', how='left')
ax2 = ax1.twinx()
line_smooth(ax2, list(x), ft_merged['ft_GLOBAL'], color=MUTED, ls=':', lw=1.5, label='F_macro')
ax2.set_ylabel('F macro (probit scale)', color=MUTED)
ax2.spines['right'].set_visible(True)
ax2.spines['right'].set_color(MUTED)

lines1, labels1 = ax1.get_legend_handles_labels()
lines2, labels2 = ax2.get_legend_handles_labels()
fig.legend(lines1 + lines2, labels1 + labels2, loc='center left',
           bbox_to_anchor=(1.0, 0.5), fontsize=8, frameon=False)

tick_every = max(1, len(labels) // 10)
ax1.set_xticks(range(0, len(labels), tick_every))
ax1.set_xticklabels([fmt_cm(labels[i]) for i in range(0, len(labels), tick_every)])

ax1.set_title(f'IBK — RD12 Mensual vs Factor Macro', fontsize=11)
save_chart(fig, '21_rd_vs_macro')

# =============================================================================
# CHART 22 — Driver PIT por tipo_ingreso_dep (PP ref: 12_driver_pit_tipo_ingreso)
# 2-panel: DEP / NO DEP — TTC, TTC_adj, PIT, RD obs, Vasicek bands
# =============================================================================

fig, axes = plt.subplots(1, 2, figsize=FIGSIZE_WIDE, sharey=False)
cohorte_fin_str = str(COHORTE_FIN)

for ax_idx, seg in enumerate(SEG_VALUES):
    ax = axes[ax_idx]
    df_seg = df_full[df_full[SEG_COL] == seg].copy()
    monthly = df_seg.groupby('codmes').agg(
        rd=(TARGET_COL, 'mean'),
        pd_ttc=('pd_ttc', 'mean'),
        pd_ttc_adj=('pd_ttc_adj', 'mean'),
        pd_pit=('pd_pit', 'mean'),
        n=('pd_pit', 'count'),
    ).reset_index().sort_values('codmes')

    x = range(len(monthly))
    xlabels = monthly['codmes'].values
    n_arr = monthly['n'].values
    pit_arr = monthly['pd_pit'].values

    # Banda IC Jeffreys 95% (q2.5/q97.5) de la RD observada
    rho_seg = rho_json['rho_by_segment'].get(seg, {}).get('rho_final', rho)
    jlo, jhi = jeffreys_band(monthly['rd'].values, n_arr, 0.025, 0.975)
    ax.fill_between(x, jlo * 100, jhi * 100, color=BAND_BLUE, alpha=0.35, zorder=1)

    # PD TTC / TTC adj: lineas suavizadas grises
    line_smooth(ax, list(x), monthly['pd_ttc'] * 100, color=TTC_GRAY, ls='--', lw=1.4, label='PD TTC')
    line_smooth(ax, list(x), monthly['pd_ttc_adj'] * 100, color=RAW_GRAY, ls='-.', lw=1.2, label='PD TTC adj')

    # PD PIT: linea suavizada verde Interbank
    plot_pit(ax, list(x), monthly['pd_pit'] * 100, label='PD PIT')

    # RD12 observada: marcador circular navy
    has_target = monthly['rd'].notna()
    plot_rd_hist(ax, [i for i, h in enumerate(has_target) if h],
                 monthly.loc[has_target, 'rd'] * 100, label='RD12 observada', ms=5)

    # RD12 proyectada (Z2): marcador circular rojo
    _sp = {p['codmes']: p['rd12_proj'] for p in
           proj_json.get('by_driver', {}).get('tipo_ingreso_dep', {}).get(seg, {}).get('projections', [])
           if p['codmes'] in PROJ_MONTHS}
    _px = [i for i, cm in enumerate(xlabels) if str(cm) in _sp]
    if _px:
        plot_rd_proj(ax, _px, [_sp[str(xlabels[i])] * 100 for i in _px], label='RD12 proyectada (Z2)', ms=6)

    # Z1/Z2 boundary
    z1_end = [i for i, cm in enumerate(xlabels) if str(cm) == cohorte_fin_str]
    if z1_end:
        ax.axvline(z1_end[0] + 0.5, color='black', ls='--', lw=0.5, alpha=0.4)

    # LRA segment
    lra_seg = lra_json['lra_by_segment'].get(seg, lra_global)
    ax.axhline(lra_seg * 100, color='black', ls='-.', lw=0.7, alpha=0.5)

    # Ticks MMM-YY
    tick_every = max(1, len(xlabels) // 8)
    ax.set_xticks(range(0, len(xlabels), tick_every))
    ax.set_xticklabels([fmt_cm(xlabels[i]) for i in range(0, len(xlabels), tick_every)], fontsize=8)
    ax.set_xlabel('Mes', fontsize=8)
    ax.set_ylabel('PD / RD (%)', fontsize=8)
    _ncell = {d['celda']: d['n_z1'] for d in pd_final_data if d['driver'] == 'tipo_ingreso_dep'}
    _n = _ncell.get(seg, 0)
    _sh = 100 * _n / sum(_ncell.values()) if _ncell else 0
    ax.set_title(f'{seg}  ·  ρ producción = {rho*100:.2f}% (global)  ·  N = {_n:,} ({_sh:.0f}%)', fontsize=9)

_h, _l = axes[0].get_legend_handles_labels()
fig.legend(_h, _l, loc='center left', bbox_to_anchor=(1.0, 0.5), fontsize=8, frameon=False)
fig.suptitle(f'IBK Z1+Z2 — tipo_ingreso_dep: PIT vs RD12', fontsize=11, y=1.02)
fig.tight_layout()
save_chart(fig, '22_driver_pit_dep')

# =============================================================================
# CHART 23 — Driver PIT por tipo_ingreso_cs (4-panel)
# =============================================================================

cs_vals = sorted(df_full['tipo_ingreso_cs'].dropna().unique(), key=str)
n_cs = len(cs_vals)
ncols = 2
nrows = int(np.ceil(n_cs / ncols))
fig, axes = plt.subplots(nrows, ncols, figsize=(7.5 * ncols, 4.2 * nrows), sharey=False)
axes = np.array(axes).reshape(-1)
for j in range(n_cs, len(axes)):
    axes[j].axis('off')

for ax_idx, cell in enumerate(cs_vals):
    ax = axes[ax_idx]
    df_cs = df_full[df_full['tipo_ingreso_cs'] == cell].copy()
    monthly = df_cs.groupby('codmes').agg(
        rd=(TARGET_COL, 'mean'),
        pd_ttc=('pd_ttc', 'mean'),
        pd_ttc_adj=('pd_ttc_adj', 'mean'),
        pd_pit=('pd_pit', 'mean'),
        n=('pd_pit', 'count'),
    ).reset_index().sort_values('codmes')

    x = range(len(monthly))
    xlabels = monthly['codmes'].values
    n_arr = monthly['n'].values
    pit_arr = monthly['pd_pit'].values

    # Banda IC Jeffreys 95% (q2.5/q97.5) de la RD observada
    seg_parent = df_cs[SEG_COL].iloc[0] if len(df_cs) else 'NO DEP'
    rho_cell = rho_json['rho_by_segment'].get(seg_parent, {}).get('rho_final', rho)
    jlo, jhi = jeffreys_band(monthly['rd'].values, n_arr, 0.025, 0.975)
    ax.fill_between(x, jlo * 100, jhi * 100, color=BAND_BLUE, alpha=0.35, zorder=1)

    # Lineas suavizadas: TTC/adj gris, PIT verde Interbank
    line_smooth(ax, list(x), monthly['pd_ttc'] * 100, color=TTC_GRAY, ls='--', lw=1.3, label='TTC')
    line_smooth(ax, list(x), monthly['pd_ttc_adj'] * 100, color=RAW_GRAY, ls='-.', lw=1.0, label='TTC adj')
    plot_pit(ax, list(x), monthly['pd_pit'] * 100, label='PIT', lw=2.0)

    has_target = monthly['rd'].notna()
    plot_rd_hist(ax, [i for i, h in enumerate(has_target) if h],
                 monthly.loc[has_target, 'rd'] * 100, label='RD obs', ms=5)

    # RD12 proyectada (Z2): marcador circular rojo
    _sp = {p['codmes']: p['rd12_proj'] for p in
           proj_json.get('by_driver', {}).get('tipo_ingreso_cs', {}).get(cell, {}).get('projections', [])
           if p['codmes'] in PROJ_MONTHS}
    _px = [i for i, cm in enumerate(xlabels) if str(cm) in _sp]
    if _px:
        plot_rd_proj(ax, _px, [_sp[str(xlabels[i])] * 100 for i in _px], label='RD12 proyectada', ms=6)

    # Z1/Z2 boundary
    z1_end = [i for i, cm in enumerate(xlabels) if str(cm) == cohorte_fin_str]
    if z1_end:
        ax.axvline(z1_end[0] + 0.5, color='black', ls='--', lw=0.5, alpha=0.4)

    tick_every = max(1, len(xlabels) // 6)
    ax.set_xticks(range(0, len(xlabels), tick_every))
    ax.set_xticklabels([fmt_cm(xlabels[i]) for i in range(0, len(xlabels), tick_every)], fontsize=7)
    ax.set_xlim(-0.5, len(xlabels) - 0.5)
    ax.set_xlabel('Mes', fontsize=7)
    if ax_idx % ncols == 0:
        ax.set_ylabel('PD / RD (%)', fontsize=8)
    _ncell = {d['celda']: d['n_z1'] for d in pd_final_data if d['driver'] == 'tipo_ingreso_cs'}
    _n = _ncell.get(cell, 0)
    _sh = 100 * _n / sum(_ncell.values()) if _ncell else 0
    ax.set_title(f'{cell}  ·  ρ producción = {rho*100:.2f}% (global)  ·  N = {_n:,} ({_sh:.0f}%)', fontsize=9)

_h, _l = axes[0].get_legend_handles_labels()
fig.legend(_h, _l, loc='center left', bbox_to_anchor=(1.0, 0.5), fontsize=8, frameon=False)
fig.suptitle(f'IBK Z1+Z2 — tipo_ingreso_cs: PIT vs RD12', fontsize=11, y=1.02)
fig.tight_layout()
save_chart(fig, '23_driver_pit_cs')

# =============================================================================
# CHART 24 — Cadena de calibración por celda (grouped bars)
# pd_ree → pd_cal → pd_ttc → pd_ttc_adj → pd_pit vs RD obs
# =============================================================================

fig, (ax1, ax2) = plt.subplots(1, 2, figsize=FIGSIZE_WIDE)

# --- Panel A: tipo_ingreso_dep ---
dep_cells = ['DEP', 'NO DEP']
bar_w = 0.12
x_dep = np.arange(len(dep_cells))
stages = ['pd_ree', 'pd_cal', 'pd_ttc', 'pd_ttc_adj', 'pd_pit', 'rd_obs']
stage_labels = ['PD raw', 'PD cal', 'PD TTC', 'TTC adj', 'PD PIT', 'RD obs']
hatches_s = ['', '////', '....', '\\\\\\\\', 'xxxx', '']
stage_colors = [RAW_GRAY, '#CFCFCF', TTC_GRAY, '#9DB8C9', IBK_GREEN, NAVY]

for s_idx, (stage, slabel, hatch) in enumerate(zip(stages, stage_labels, hatches_s)):
    vals = []
    for cell in dep_cells:
        drv = [d for d in pd_final_data if d['celda'] == cell and d['driver'] == 'tipo_ingreso_dep']
        if drv:
            d = drv[0]
            if stage == 'rd_obs':
                vals.append(d['rd_obs'] * 100)
            elif stage == 'pd_ree':
                vals.append(d['pd_ree_mean'] * 100)
            elif stage == 'pd_cal':
                vals.append(d['pd_cal_mean'] * 100)
            elif stage == 'pd_ttc':
                vals.append(d['pd_ttc_mean'] * 100)
            elif stage == 'pd_ttc_adj':
                # Compute from parquet
                sub = df_full[(df_full[SEG_COL] == cell) &
                              (df_full['codmes'].astype(str) <= cohorte_fin_str)]
                vals.append(sub['pd_ttc_adj'].mean() * 100)
            elif stage == 'pd_pit':
                vals.append(d['pd_pit_mean'] * 100)
        else:
            vals.append(0)

    offset = (s_idx - 2.5) * bar_w
    bars = ax1.bar(x_dep + offset, vals, bar_w * 0.9,
                   facecolor=stage_colors[s_idx], edgecolor='white',
                   linewidth=0.4, label=slabel)
    # Value labels on top
    for bar, v in zip(bars, vals):
        ax1.text(bar.get_x() + bar.get_width() / 2, v + 0.15,
                 f'{v:.1f}', ha='center', va='bottom', fontsize=6, rotation=90)

ax1.set_xticks(x_dep)
ax1.set_xticklabels(dep_cells)
ax1.set_ylabel('PD / RD (%)')
ax1.set_title('tipo_ingreso_dep', fontsize=10)
_h, _l = ax1.get_legend_handles_labels()
fig.legend(_h, _l, loc='center left', bbox_to_anchor=(1.0, 0.5), fontsize=8, frameon=False)

# --- Panel B: tipo_ingreso_cs ---
cs_cells = sorted(df_full['tipo_ingreso_cs'].dropna().unique(), key=str)
x_cs = np.arange(len(cs_cells))

for s_idx, (stage, slabel, hatch) in enumerate(zip(stages, stage_labels, hatches_s)):
    vals = []
    for cell in cs_cells:
        drv = [d for d in pd_final_data if d['celda'] == cell and d['driver'] == 'tipo_ingreso_cs']
        if drv:
            d = drv[0]
            if stage == 'rd_obs':
                vals.append(d['rd_obs'] * 100)
            elif stage == 'pd_ree':
                vals.append(d['pd_ree_mean'] * 100)
            elif stage == 'pd_cal':
                vals.append(d['pd_cal_mean'] * 100)
            elif stage == 'pd_ttc':
                vals.append(d['pd_ttc_mean'] * 100)
            elif stage == 'pd_ttc_adj':
                sub = df_full[(df_full['tipo_ingreso_cs'] == cell) &
                              (df_full['codmes'].astype(str) <= cohorte_fin_str)]
                vals.append(sub['pd_ttc_adj'].mean() * 100)
            elif stage == 'pd_pit':
                vals.append(d['pd_pit_mean'] * 100)
        else:
            vals.append(0)

    offset = (s_idx - 2.5) * bar_w
    bars = ax2.bar(x_cs + offset, vals, bar_w * 0.9,
                   facecolor=stage_colors[s_idx], edgecolor='white',
                   linewidth=0.4)
    for bar, v in zip(bars, vals):
        ax2.text(bar.get_x() + bar.get_width() / 2, v + 0.15,
                 f'{v:.1f}', ha='center', va='bottom', fontsize=5.5, rotation=90)

ax2.set_xticks(x_cs)
ax2.set_xticklabels(cs_cells, fontsize=7.5)
ax2.set_ylabel('PD / RD (%)')
ax2.set_title('tipo_ingreso_cs', fontsize=10)

fig.suptitle(f'IBK Z1 — Cadena calibración por celda: '
             f'PD raw → cal → TTC → TTC adj → PIT vs RD',
             fontsize=11, y=1.02)
fig.tight_layout()
save_chart(fig, '24_cadena_calibracion_por_driver')

# =============================================================================
# CHART 25 — Desagregacion de rho: global -> por segmento (driver)
# =============================================================================

fig, ax = plt.subplots(figsize=FIGSIZE)
_rseg = rho_json['rho_by_segment']
_items = [
    ('Global (producción)', rho_json['rho_final'], rho_json['n_meses'], MUTED),
    ('DEP', _rseg['DEP']['rho_final'], _rseg['DEP']['n_meses'], CAT_COLORS[0]),
    ('NO DEP', _rseg['NO DEP']['rho_final'], _rseg['NO DEP']['n_meses'], CAT_COLORS[1]),
]
_xp = list(range(len(_items)))
_bars = ax.bar(_xp, [it[1] * 100 for it in _items], width=0.55,
               color=[it[3] for it in _items], edgecolor='white', linewidth=0.5)
for b, it in zip(_bars, _items):
    ax.text(b.get_x() + b.get_width() / 2, it[1] * 100 + 0.05,
            f'{it[1]*100:.2f}%\nn={it[2]}m', ha='center', va='bottom', fontsize=8.5)
ax.axhline(RHO_FLOOR * 100, color='black', ls='-.', lw=1,
           label=f'Floor Basel retail = {RHO_FLOOR*100:.2f}%')
ax.set_xticks(_xp)
ax.set_xticklabels([it[0] for it in _items])
ax.set_ylabel('ρ correlación de activos (%)')
ax.set_title('Desagregación de ρ (método de momentos): global → por segmento', fontsize=11)
ax.legend(loc='upper left', fontsize=8)
ax.text(0.5, -0.20,
        'Global: 201901–202504 excl COVID (64m).   Segmento: 202201–202504 (40m, spike incluido).   '
        'Celdas tipo_ingreso_cs heredan el ρ de su segmento padre.   '
        'La PD de producción aplica el ρ GLOBAL uniforme; el ρ por segmento es referencia (no usado en la PD).',
        transform=ax.transAxes, ha='center', va='top', fontsize=7, color=MUTED, style='italic')
save_chart(fig, '25_rho_desagregado')

# =============================================================================
# SUMMARY
# =============================================================================

charts = sorted(CHART_DIR.glob('*.png'))
print(f"\n{'=' * 70}")
print(f"  11 COMPLETADO — {len(charts)} charts generados")
print(f"{'=' * 70}")
for c in charts:
    print(f"  {c.name} ({c.stat().st_size:,} bytes)")
