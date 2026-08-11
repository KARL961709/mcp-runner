# -*- coding: utf-8 -*-
"""
calibrar.py -- re-ajuste de la cadena de calibracion Origen Bank BPE.

Uso:  python calibrar.py <ruta_parquet_o_carpeta>

Insumo: disc_model_owner.ds_adm_bpe_insumo_calib_v4  (salida de 11_insumo_calibracion.sql)

Corre en cuatro pasos y el PASO 0 es una compuerta: si la cadena no reproduce la
calibracion vigente al bit, todo lo que sigue seria una reimplementacion distinta
comparada contra si misma, y no dice nada. En ese caso el script para.

  0  REPRODUCIR la vigente         gate, tolerancia 1e-9
  1  AJUSTAR variantes             misma cadena, distinta poblacion de ajuste
  2  BACKTEST                      nivel, pendiente y sesgo por banda x poblacion
  3  OUT OF TIME                   ajusta con los trimestres viejos, evalua en los nuevos

Nada aca elige por su cuenta: imprime las variantes y el criterio, la decision es humana.
"""
import sys, os, glob, json
import numpy as np
import pandas as pd
from scipy.stats import norm
from scipy.optimize import minimize
from sklearn.isotonic import IsotonicRegression

RUTA = sys.argv[1] if len(sys.argv) > 1 else "."

# ---------------------------------------------------------------- cadena vigente
RHO = 0.0359788172683254
LAM = 0.35
CAP = (-1.1568688592667788, 2.0194314436566057)
VIG = {
    "PNN": dict(forma="beta",  b=[-0.6601884802657757, 0.5938923689532265, 0.1076643929596169],
                lra=0.0977852068533222, reancla=1.1629910458377239),
    "PJJ": dict(forma="logit", b=[-0.1599325996266291, 0.9675398918720501],
                lra=0.0773146675151130, reancla=1.1368505987482271),
}
# Era Impulsa: el ajuste original la excluye del re-ancla y del f_t.
IMPULSA = (202310, 202412)


def rho_basel(p):
    k = (1 - np.exp(-35 * p)) / (1 - np.exp(-35.0))
    return 0.03 * k + 0.16 * (1 - k)


def nivel(p, forma, b):
    p = np.clip(p, 1e-9, 1 - 1e-9)
    z = (b[0] + b[1] * np.log(p) + b[2] * np.log(1 - p)) if forma == "beta" \
        else (b[0] + b[1] * np.log(p / (1 - p)))
    return 1.0 / (1.0 + np.exp(-z))


def cadena(praw, pers, fhat, C, iso=None, lam=LAM):
    """pd_raw -> pd_pit. Devuelve (pd_cal, rho_i, pd_pit)."""
    pdc = np.empty_like(praw, dtype=float)
    ri = np.empty_like(praw, dtype=float)
    out = np.empty_like(praw, dtype=float)
    for k, cf in C.items():
        m = (pers == k)
        if not m.any():
            continue
        pc = nivel(praw[m], cf["forma"], cf["b"])
        r = np.clip(RHO * rho_basel(pc) / rho_basel(cf["lra"]), 0.001, 0.999)
        f = np.clip(fhat[m], CAP[0], CAP[1])
        pit = norm.cdf((norm.ppf(np.clip(pc, 1e-12, 1 - 1e-12)) - np.sqrt(r) * lam * f) / np.sqrt(1 - r))
        pdc[m], ri[m], out[m] = pc, r, pit * cf["reancla"]
    if iso is not None:
        out = np.clip(iso.predict(out), 1e-6, 1 - 1e-6)
    return pdc, ri, out


def fit_nivel(p, y, w, forma):
    p = np.clip(p, 1e-9, 1 - 1e-9)
    X = np.vstack([np.ones_like(p), np.log(p), np.log(1 - p)]).T if forma == "beta" \
        else np.vstack([np.ones_like(p), np.log(p / (1 - p))]).T

    def nll(b):
        z = np.clip(X @ b, -35, 35)
        q = 1.0 / (1.0 + np.exp(-z))
        return -np.sum(w * (y * np.log(q + 1e-12) + (1 - y) * np.log(1 - q + 1e-12)))

    b0 = np.zeros(X.shape[1]); b0[1] = 1.0
    r = minimize(nll, b0, method="BFGS", options=dict(maxiter=6000))
    if not r.success:
        r = minimize(nll, b0, method="Nelder-Mead", options=dict(maxiter=20000, fatol=1e-10))
    return [float(x) for x in r.x]


def ajustar(g, w, con_iso=False, lam=LAM):
    """Ajusta nivel + LRA + re-ancla sobre g. La re-ancla fuerza pd_pit insesgado."""
    C = {}
    for k, forma in [("PNN", "beta"), ("PJJ", "logit")]:
        s = g[g.pers == k]
        if len(s) < 200:
            C[k] = dict(VIG[k]); continue
        ws = w[g.pers.values == k]
        C[k] = dict(forma=forma,
                    b=fit_nivel(s.pd_raw.values, s.target_12m.values, ws, forma),
                    lra=float(np.average(s.target_12m, weights=ws)), reancla=1.0)
    _, _, pit = cadena(g.pd_raw.values, g.pers.values, g.fhat.values, C, lam=lam)
    for k in ["PNN", "PJJ"]:
        m = (g.pers.values == k)
        if m.sum() < 200:
            continue
        C[k]["reancla"] = float(np.average(g.target_12m.values[m], weights=w[m]) /
                                np.average(pit[m], weights=w[m]))
    iso = None
    if con_iso:
        _, _, pit2 = cadena(g.pd_raw.values, g.pers.values, g.fhat.values, C, lam=lam)
        iso = IsotonicRegression(y_min=1e-6, y_max=0.999, out_of_bounds="clip")
        iso.fit(pit2, g.target_12m.values, sample_weight=w)
    return C, iso


LO = lambda x: np.log(np.clip(x, 1e-9, 1 - 1e-9) / (1 - np.clip(x, 1e-9, 1 - 1e-9)))
BANDAS = [(0, .02), (.02, .04), (.04, .06), (.06, .08), (.08, .10),
          (.10, .13), (.13, .16), (.16, .20), (.20, .30), (.30, 1.01)]


def pendiente(s, col, w):
    X, Y, W = [], [], []
    for a, b in BANDAS:
        k = (s[col].values >= a) & (s[col].values < b)
        if k.sum() < 30:
            continue
        rd = np.average(s.target_12m.values[k], weights=w[k])
        if rd <= 0 or rd >= 1:
            continue
        X.append(LO(np.average(s[col].values[k], weights=w[k]))); Y.append(LO(rd)); W.append(w[k].sum())
    if len(X) < 4:
        return np.nan
    X, Y, W = np.array(X), np.array(Y), np.array(W)
    A = np.vstack([np.ones_like(X), X]).T
    return float(np.linalg.solve(A.T @ np.diag(W) @ A, A.T @ np.diag(W) @ Y)[1])


# ------------------------------------------------------------------------ carga
def cargar(ruta):
    if os.path.isdir(ruta):
        fs = sorted(glob.glob(os.path.join(ruta, "**", "*"), recursive=True))
        fs = [f for f in fs if os.path.isfile(f) and os.path.getsize(f) > 1000]
        if not fs:
            sys.exit("no encontre archivos en %s" % ruta)
        print("leyendo %d archivo(s)" % len(fs))
        return pd.concat([pd.read_parquet(f) for f in fs], ignore_index=True)
    return pd.read_parquet(ruta)


df = cargar(RUTA)
for c in ["pd_raw", "fhat", "pd_cal_vig", "rho_i_vig", "pd_pit_vig", "target_06m", "target_09m",
          "target_12m", "flg_clean", "flg_calib", "flg_ppjj", "flg_impulsa", "codmes", "trimestre"]:
    if c in df.columns:
        df[c] = pd.to_numeric(df[c], errors="coerce")
df["pers"] = np.where(df.flg_ppjj.values == 1, "PJJ", "PNN")
df["w"] = 1.0
print(f"filas {len(df):,}  |  poblaciones {df.pob.value_counts().to_dict()}")
print(f"codmes {int(df.codmes.min())}-{int(df.codmes.max())}  |  "
      f"evaluables a 12m {int(df.target_12m.notna().sum()):,}")

# ------------------------------------------------------------- 0  GATE
print("\n" + "=" * 82)
print("PASO 0  REPRODUCIR LA CADENA VIGENTE   (compuerta: sin esto nada de abajo vale)")
print("=" * 82)
ok = df.pd_raw.notna() & df.fhat.notna() & df.pd_pit_vig.notna()
pdc, ri, pit = cadena(df.pd_raw.values, df.pers.values, df.fhat.values, VIG)
peor = 0.0
for nom, mio, suyo in [("pd_cal", pdc, df.pd_cal_vig.values),
                       ("rho_i", ri, df.rho_i_vig.values),
                       ("pd_pit", pit, df.pd_pit_vig.values)]:
    m = ok.values & pd.notna(suyo)
    d = float(np.abs(mio[m] - suyo[m]).max()); peor = max(peor, d)
    print(f"  {nom:<10} n={m.sum():>9,}   max|dif| = {d:.3e}")
if peor > 1e-9:
    sys.exit("\n>>> NO REPRODUCE (max|dif| = %.3e). Reviso los coeficientes antes de seguir." % peor)
print("\n  >>> reproduce. La cadena implementada es la misma que corre en produccion.")

# ------------------------------------------------------------- 0B  EL CICLO
# La ventana de ajuste (202206-202506) tiene una mora muy superior a la de las cosechas
# recientes. Quien tiene que cerrar esa brecha es el ajuste PIT: f_t con lambda. Antes de
# tocar la poblacion de ajuste hay que saber si el f_t sigue al ciclo y si su amplitud alcanza.
print("\n" + "=" * 88)
print("PASO 0B  EL CICLO   f_t sigue a la mora realizada? y le alcanza la amplitud?")
print("=" * 88)
EV0 = df.target_12m.notna() & df.pd_raw.notna() & df.fhat.notna()
q = (df[EV0 & df.flg_clean.eq(1)]
     .groupby("trimestre")
     .agg(n=("target_12m", "size"), rd=("target_12m", "mean"),
          fhat=("fhat", "mean"), praw=("pd_raw", "mean")).reset_index())
q = q[q.n >= 200]
print(f"\n{'trim':>8}{'n':>9}{'RD 12m':>9}{'pd_raw':>9}{'fhat':>9}")
for _, r in q.iterrows():
    print(f"{int(r.trimestre):>8}{int(r.n):>9,}{100*r.rd:>8.2f}%{100*r.praw:>8.2f}%{r.fhat:>9.3f}")
MIN_TRIM = 8   # con menos trimestres la correlacion y el lambda implicito son ruido
if len(q) < MIN_TRIM:
    print(f"\n  solo {len(q)} trimestres con muestra suficiente: NO alcanza para leer el ciclo.")
    print(f"  Hacen falta al menos {MIN_TRIM}. Con la ventana completa (202206-202506) deberian")
    print("  ser ~13. Si esto aparece con el insumo real, algo se filtro de mas.")
else:
    cc = float(np.corrcoef(q.fhat, LO(q.rd))[0, 1])
    print(f"\n  correlacion fhat vs logit(RD) sobre {len(q)} trimestres: {cc:+.3f}")
    print("  el signo esperado es NEGATIVO: f_t entra restando en el shift de Vasicek,")
    print("  asi que f_t alto = ciclo benigno = menos mora.")
    if cc > 0:
        print("  >>> SIGNO INVERTIDO. Antes de tocar lambda hay que revisar el f_t.")
    amp_f = float(q.fhat.max() - q.fhat.min())
    amp_rd = float(abs(LO(q.rd.max()) - LO(q.rd.min())))
    rr = np.clip(RHO * rho_basel(q.praw.values) / rho_basel(0.09), 0.001, 0.999)
    esc = float(np.mean(np.sqrt(rr) / np.sqrt(1 - rr)))
    lam_imp = amp_rd / max(amp_f * esc, 1e-9)
    print(f"\n  amplitud de fhat {amp_f:6.3f}   amplitud del ciclo en logit(RD) {amp_rd:6.3f}")
    print(f"  lambda vigente {LAM:.2f}   |   lambda que igualaria esa amplitud ~ {lam_imp:.2f}")
    if cc < 0 and lam_imp > LAM * 1.5:
        print("\n  >>> el ajuste macro es MAS CHICO que el ciclo que tiene que absorber.")
        print("      Parte del sesgo de nivel no es poblacion de ajuste: es lambda.")
        print("      Las variantes F, G y H miden eso.")
    elif cc < 0:
        print("\n  >>> la amplitud de lambda alcanza. El sesgo de nivel es de poblacion, no de ciclo.")

# ------------------------------------------------------------- 1  VARIANTES
EV = df.target_12m.notna() & df.pd_raw.notna() & df.fhat.notna()
CLEAN = df.flg_clean.eq(1)
NOIMP = ~df.codmes.between(*IMPULSA)
POB = {"IBK": df.pob.eq("IBK"), "TOP4": df.pob.isin(["IBK", "RESTO_TOP4"]), "TODO": df.pob.notna()}

#                nombre                          poblacion de ajuste            iso    lambda
VARIANTES = [
    ("A  IBK, ex-Impulsa",        EV & CLEAN & NOIMP & POB["IBK"],  False, LAM),
    ("B  IBK+TOP4, ex-Impulsa",   EV & CLEAN & NOIMP & POB["TOP4"], False, LAM),
    ("C  IBK+TOP4 con Impulsa",   EV & CLEAN & POB["TOP4"],         False, LAM),
    ("D  todo el libro",          EV & CLEAN & NOIMP & POB["TODO"], False, LAM),
    ("E  IBK+TOP4 + isotonica",   EV & CLEAN & NOIMP & POB["TOP4"], True,  LAM),
    ("F  IBK, lambda 0.55",       EV & CLEAN & NOIMP & POB["IBK"],  False, 0.55),
    ("G  IBK+TOP4, lambda 0.55",  EV & CLEAN & NOIMP & POB["TOP4"], False, 0.55),
    ("H  IBK+TOP4, lambda 0.75",  EV & CLEAN & NOIMP & POB["TOP4"], False, 0.75),
]

print("\n" + "=" * 108)
print("PASO 1 y 2  AJUSTE Y BACKTEST      ratio = PD asignada / mora observada.  1.00 = insesgado")
print("=" * 108)
print(f"{'variante':<26}{'lam':>6}{'n ajuste':>10}{'PNN b1':>8}{'PJJ b1':>8}{'ra PNN':>8}{'ra PJJ':>8}"
      f"{'IBK':>7}{'TOP4':>7}{'SSFF':>7}{'SSFF>=10%':>11}{'b SSFF':>8}")
print("-" * 114)
RES = {}
for nom, mask, iso_on, lam in VARIANTES:
    g = df[mask]
    if len(g) < 500:
        print(f"{nom:<26}  muestra insuficiente ({len(g)})"); continue
    C, iso = ajustar(g, g.w.values, con_iso=iso_on, lam=lam)
    _, _, p = cadena(df.pd_raw.values, df.pers.values, df.fhat.values, C, iso, lam=lam)
    df["px"] = p
    rr = []
    for pb in ["IBK", "RESTO_TOP4", "SSFF"]:
        s = df[EV & df.pob.eq(pb) & CLEAN]
        rr.append(np.average(s.px, weights=s.w) / np.average(s.target_12m, weights=s.w))
    s = df[EV & df.pob.eq("SSFF") & CLEAN]
    hi = s[s.px >= .10]
    alto = np.average(hi.px, weights=hi.w) / np.average(hi.target_12m, weights=hi.w) if len(hi) > 50 else np.nan
    bs = pendiente(s, "px", s.w.values)
    RES[nom] = dict(C=C, iso=iso_on, lam=lam, ratios=rr, alto=float(alto), b_ssff=float(bs), n=int(len(g)))
    print(f"{nom:<26}{lam:>6.2f}{len(g):>10,}{C['PNN']['b'][1]:>8.3f}{C['PJJ']['b'][1]:>8.3f}"
          f"{C['PNN']['reancla']:>8.3f}{C['PJJ']['reancla']:>8.3f}"
          f"{rr[0]:>7.2f}{rr[1]:>7.2f}{rr[2]:>7.2f}{alto:>11.2f}{bs:>8.2f}")

print("\n  SSFF>=10%  es el tramo donde opera el corte de campanas.")
print("  Debajo de 1.00 la PD queda por DEBAJO de la mora observada: leads aprobados mal precificados.")

# ------------------------------------------------------------- 3  OUT OF TIME
print("\n" + "=" * 92)
print("PASO 3  OUT OF TIME   ajusta con los trimestres viejos, evalua en los nuevos")
print("=" * 92)
tr = sorted(df.loc[EV, "trimestre"].dropna().unique())
corte = tr[int(len(tr) * 0.7)] if len(tr) >= 6 else None
if corte is None:
    print("  trimestres insuficientes para partir")
else:
    print(f"  ajuste hasta {int(corte)}  |  evaluacion desde {int(corte)}  ({len(tr)} trimestres)")
    print(f"\n{'variante':<26}{'IBK':>8}{'TOP4':>8}{'SSFF':>8}{'SSFF>=10%':>12}")
    print("-" * 62)
    for nom, mask, iso_on, lam in VARIANTES:
        g = df[mask & df.trimestre.lt(corte)]
        if len(g) < 500:
            continue
        C, iso = ajustar(g, g.w.values, con_iso=iso_on, lam=lam)
        _, _, p = cadena(df.pd_raw.values, df.pers.values, df.fhat.values, C, iso, lam=lam)
        df["px"] = p
        out = df[EV & CLEAN & df.trimestre.ge(corte)]
        fila = f"{nom:<26}"
        for pb in ["IBK", "RESTO_TOP4", "SSFF"]:
            s = out[out.pob == pb]
            fila += f"{np.average(s.px,weights=s.w)/np.average(s.target_12m,weights=s.w):>8.2f}" if len(s) > 100 else f"{'.':>8}"
        s = out[(out.pob == "SSFF") & (out.px >= .10)]
        fila += f"{np.average(s.px,weights=s.w)/np.average(s.target_12m,weights=s.w):>12.2f}" if len(s) > 100 else f"{'.':>12}"
        print(fila)

# ------------------------------------------------------------- salida
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "outputs")
os.makedirs(OUT, exist_ok=True)
json.dump({k: {"coeficientes": v["C"], "isotonica": v["iso"], "lambda": v["lam"], "n_ajuste": v["n"],
               "ratio_IBK": v["ratios"][0], "ratio_TOP4": v["ratios"][1],
               "ratio_SSFF": v["ratios"][2], "ratio_SSFF_alto": v["alto"],
               "pendiente_SSFF": v["b_ssff"]} for k, v in RES.items()},
          open(os.path.join(OUT, "variantes_calib_v4.json"), "w"), indent=2, ensure_ascii=False)
print(f"\nescrito outputs/variantes_calib_v4.json  ({len(RES)} variantes)")
print("\nNINGUNA VARIANTE SE ADOPTA SOLA. El criterio de decision esta en LEEME.md.")
