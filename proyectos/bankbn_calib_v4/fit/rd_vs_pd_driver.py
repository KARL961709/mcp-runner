# -*- coding: utf-8 -*-
"""
rd_vs_pd_driver.py -- regenera la tabla rd_vs_pd_driver desde el insumo de calib_v4.

Uso:  python rd_vs_pd_driver.py <ruta_parquet> [salida.xlsx]

Campos, los mismos de la hoja 1_clean_dirty del entregable de 2026-08-10:
    poblacion driver codmes n n_target maduro h_disp fhat
    pd_raw_pct pd_pit_pct rd12_pct rd06_pct proy_V1_pct proy_V2_pct proy_V3_pct

Dos diferencias declaradas respecto de aquel Excel:

 1. El bloque clean+dirty se define con flg_clean_calib <> 99, que es el flag de la
    CALIBRACION. El entregable anterior uso flg_clean, que 5b_cal_scored.sql redefine
    como binario con menos filtros. Son poblaciones distintas.

 2. Las tres proyecciones son una REIMPLEMENTACION de los metodos declarados en
    PROPUESTA_FINAL_V2.md (multiplicador, chain-ladder, regresion logit). El script
    original no se conserva, asi que los valores no tienen por que coincidir al decimal
    con los del Excel viejo. El metodo si es el mismo.

Y una advertencia que viene de la propia propuesta (limitacion 5): con horizonte
disponible menor a 6 meses la RD es casi cero estructural y el multiplicador se dispara.
Esas proyecciones salen marcadas en la columna proy_confiable.
"""
import sys, os
import numpy as np
import pandas as pd

RUTA = sys.argv[1] if len(sys.argv) > 1 else "."
SAL = sys.argv[2] if len(sys.argv) > 2 else "rd_vs_pd_driver_v2.csv"
CORTE = 202606                      # ultimo mes de RCC disponible
H = [1, 2, 3, 6, 9, 12]             # horizontes con target en el insumo
LO = lambda p: np.log(np.clip(p, 1e-6, 1 - 1e-6) / (1 - np.clip(p, 1e-6, 1 - 1e-6)))
IL = lambda z: 1 / (1 + np.exp(-z))


def meses(a, b):
    return (b // 100 - a // 100) * 12 + (b % 100 - a % 100)


def cargar(ruta):
    import glob
    fs = [ruta] if os.path.isfile(ruta) else sorted(glob.glob(os.path.join(ruta, "**", "*"), recursive=True))
    fs = [f for f in fs if os.path.isfile(f) and os.path.getsize(f) > 1000]
    if not fs:
        sys.exit("no encontre archivos en %s" % ruta)
    return pd.concat([pd.read_parquet(f) for f in fs], ignore_index=True)


df = cargar(RUTA)
for c in ["codmes", "flg_ppjj", "flg_clean_calib", "pd_raw", "fhat", "pd_pit_vig"] + \
         [f"target_{h:02d}m" for h in H]:
    df[c] = pd.to_numeric(df[c], errors="coerce")
df = df[df.flg_clean_calib != 99]                       # clean + dirty, sin exclusion estructural
df["driver"] = np.where(df.flg_ppjj == 1, "PJJ", "PNN")
print(f"filas clean+dirty {len(df):,}   codmes {int(df.codmes.min())}-{int(df.codmes.max())}")

filas = []
for pob, gp in df.groupby("pob"):
    for drv in ["GLOBAL", "PNN", "PJJ"]:
        g = gp if drv == "GLOBAL" else gp[gp.driver == drv]
        for cm, s in g.groupby("codmes"):
            cm = int(cm); hd = meses(cm, CORTE)
            f = dict(poblacion=pob, driver=drv, codmes=cm, n=len(s),
                     n_target=int(s.target_12m.notna().sum()),
                     maduro="SI" if hd >= 12 else "NO", h_disp=hd,
                     fhat=float(s.fhat.mean()),
                     pd_raw_pct=100 * s.pd_raw.mean(),
                     pd_pit_pct=100 * s.pd_pit_vig.mean())
            for h in H:
                v = s[f"target_{h:02d}m"]
                f[f"rd{h:02d}_pct"] = 100 * v.mean() if v.notna().any() else np.nan
            filas.append(f)
t = pd.DataFrame(filas)

# --------- proyeccion de RD12 para cosechas inmaduras, tres metodos
t["h_base"] = [max([h for h in H if h < 12 and hd >= h], default=np.nan) for hd in t.h_disp]
mad = t[(t.maduro == "SI") & t.rd12_pct.notna()]
for c in ["proy_V1_pct", "proy_V2_pct", "proy_V3_pct"]:
    t[c] = np.nan

for (pob, drv), g in t.groupby(["poblacion", "driver"]):
    ref = mad[(mad.poblacion == pob) & (mad.driver == drv)]
    if len(ref) < 8:
        continue
    for h in [h for h in H if h < 12]:
        col = f"rd{h:02d}_pct"
        r = ref[(ref[col] > 0) & ref[col].notna()]
        if len(r) < 6:
            continue
        w = r.n.values
        mult = np.average(r.rd12_pct / r[col], weights=w)                       # V1 multiplicador
        cl = np.sum(w * r.rd12_pct) / np.sum(w * r[col])                        # V2 chain-ladder
        x, y = LO(r[col].values / 100), LO(r.rd12_pct.values / 100)             # V3 logit
        A = np.vstack([np.ones_like(x), x]).T
        M = np.diag(w)
        a, b = np.linalg.solve(A.T @ M @ A, A.T @ M @ y)
        k = (t.poblacion == pob) & (t.driver == drv) & (t.maduro == "NO") & (t.h_base == h) & t[col].notna()
        t.loc[k, "proy_V1_pct"] = t.loc[k, col] * mult
        t.loc[k, "proy_V2_pct"] = t.loc[k, col] * cl
        t.loc[k, "proy_V3_pct"] = 100 * IL(a + b * LO(t.loc[k, col].values / 100))

t["proy_confiable"] = np.where(t.maduro == "SI", "", np.where(t.h_base >= 6, "SI", "NO  h<6"))
COLS = ["poblacion", "driver", "codmes", "n", "n_target", "maduro", "h_disp", "fhat",
        "pd_raw_pct", "pd_pit_pct", "rd12_pct", "rd09_pct", "rd06_pct", "rd03_pct",
        "h_base", "proy_V1_pct", "proy_V2_pct", "proy_V3_pct", "proy_confiable"]
t = t[COLS].sort_values(["poblacion", "driver", "codmes"])
for c in t.columns:
    if c.endswith("_pct") or c == "fhat":
        t[c] = t[c].round(4)

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), SAL)
out = out.replace(".xlsx", ".csv")
t.to_csv(out, index=False)
print(f"\n{len(t)} filas   ->   {out}")
print(t.groupby(["poblacion", "driver"]).size().to_string())
print(f"\ncon proyeccion: {t.proy_V1_pct.notna().sum()} filas "
      f"({(t.proy_confiable == 'SI').sum()} confiables, "
      f"{(t.proy_confiable.str.startswith('NO')).sum()} con h<6)")
