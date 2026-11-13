""" Calculo de la calibracion (codigo del inference.py). El pkl solo trae los parametros (estado):
modelo, id_calibracion, fecha y por producto: sufijo, variables, modelo_macro (forma + coeficientes + topes)
y filas (metodo TTC por celda: Beta / Platt / tramos isotonicos, anclas, rho, lambda, capeos). """

import numpy as np
import pandas as pd
from scipy.stats import norm

COMODIN = "*"
LLAVES = ["llave_01", "llave_02", "llave_03", "llave_04"]
MAX_VARIABLES = 6
BLOQUE = ["factor_macro", "factor_macro_freeze", "prob_modelo_cal", "puntuacion_cal",
          "prob_modelo_cal_freeze", "puntuacion_cal_freeze", "prob_modelo_cal_smacro", "puntuacion_cal_smacro"]
EXTRAS = [f"extra_{i:02d}" for i in range(1, 9)]
BASE = ["cod_mes", "cod_tip_doc", "key_value", "cod_cli", "prob_modelo", "puntuacion"]
POR_METODO = {"BETA": ["beta_m", "beta_a", "beta_b"], "PLATT": ["platt_a", "platt_b"], "ISOTONICA": ["x_lo", "x_hi", "y_lo", "y_hi"]}
CONVENCION = {"FT_VASICEK": "VASICEK", "LINEAL_CAP": "DIRECTO"}


def slot_mes(k):
    return f"var_macro_{2 * k - 1:02d}"


def slot_freeze(k):
    return f"var_macro_{2 * k:02d}"


# ------------------------------------------------------------ estructura del scr
def columnas_scr(m):
    bloques = [c + p["sufijo"] for p in m.productos.values() if p["sufijo"] != "EXTRA" for c in BLOQUE]
    return BASE + bloques + ["id_calibracion"] + EXTRAS + ["p_codmes", "p_fecdia"]

# ------------------------------------------------------------ controles del pkl
def validar(m):
    err, sufijos = [], {}
    extra = [n for n, p in m.productos.items() if p["sufijo"] == "EXTRA"]
    if len(extra) > 1:
        err.append(f"EXTRAS: solo un producto puede ir en los 8 extras y hay {len(extra)} ({extra})")
    for nombre, p in m.productos.items():
        if p["sufijo"] != "EXTRA":
            if p["sufijo"] in sufijos:
                err.append(f"SUFIJO: {nombre} y {sufijos[p['sufijo']]} escriben el mismo bloque {p['sufijo']}")
            sufijos[p["sufijo"]] = nombre
        if any(k < 1 or k > MAX_VARIABLES for k in p["variables"]):
            err.append(f"{nombre}: variable macro fuera de 1..{MAX_VARIABLES} (12 columnas var_macro = 6 variables x 2)")
        f, mm = p["filas"], p["modelo_macro"]
        esq = _esquema(f)
        met = esq.get("metodo")
        if met not in POR_METODO:
            err.append(f"{nombre}: metodo {met!r} invalido")
        tiene_vas = (f.bloque == "VASICEK").any()
        if (mm is None) != (not tiene_vas):
            err.append(f"{nombre}: modelo_macro y bloque VASICEK deben ir juntos (PIT) o ninguno (TTC)")
        if mm is not None:
            if CONVENCION.get(mm["tipo"]) != esq.get("convencion_macro"):
                err.append(f"{nombre}: modelo_macro {mm['tipo']} no corresponde a la convencion {esq.get('convencion_macro')}")
            n_coef = len(mm["pendientes"] if mm["tipo"] == "FT_VASICEK" else mm["beta"])
            if n_coef != len(p["variables"]):
                err.append(f"{nombre}: {n_coef} coeficientes para {len(p['variables'])} variables")
            rho = f[(f.bloque == "VASICEK") & (f.parametro == "rho")].valor
            if not ((rho > 0) & (rho < 1)).all():
                err.append(f"{nombre}: rho fuera de (0,1)")
    return err

# ------------------------------------------------------------ x -> f_t (un solo f_t aunque haya varias x)
def factor(m, nombre, xs):
    p = m.productos[nombre]
    mm = p["modelo_macro"]
    if mm["tipo"] == "FT_VASICEK":
        rho = _rho_unico(p["filas"])
        lin = mm["intercepto"]
        for b, x in zip(mm["pendientes"], xs):
            lin = lin + b * x
        f = (norm.ppf(mm["pd_lra"]) - np.sqrt(1.0 - rho) * lin) / np.sqrt(rho) - mm["media_centrado"]
        return np.maximum(np.minimum(f, mm["ft_max"]), mm["ft_min"])
    f = 0.0
    for b, mu, x in zip(mm["beta"], mm["mu"], xs):
        f = f + b * (x - mu)
    return np.maximum(mm["cap_lo"], np.minimum(mm["cap_hi"], f))

# ------------------------------------------------------------ ds -> scr
def calcular(m, ds):
    n = len(ds)
    scr = pd.DataFrame(index=ds.index, columns=columnas_scr(m), dtype=object)
    for c in BASE + ["p_codmes", "p_fecdia"]:
        scr[c] = ds[c]
    scr["id_calibracion"] = m.id_calibracion
    for c in EXTRAS:
        scr[c] = ""
    for nombre, p in m.productos.items():
        f = p["filas"]
        esq = _esquema(f)
        k = _llaves_cliente(ds, esq)
        v = lambda b, q, d=np.nan: _resolver(f, b, q, k, n, d)  # noqa: E731

        def clip(x, a, b):
            lo, hi = v("CLIP", a), v("CLIP", b)
            return np.clip(x, np.nan_to_num(lo, nan=-np.inf), np.nan_to_num(hi, nan=np.inf))

        pr = clip(ds["prob_modelo"].to_numpy(dtype="float64"), "p_min", "p_max")
        met = esq["metodo"]
        if met == "BETA":
            pd_cal = 1.0 / (1.0 + np.exp(-(v("BETA", "beta_m") + v("BETA", "beta_a") * np.log(pr) - v("BETA", "beta_b") * np.log(1.0 - pr))))
        elif met == "PLATT":
            pd_cal = 1.0 / (1.0 + np.exp(-(v("PLATT", "platt_a") * np.log(pr / (1.0 - pr)) + v("PLATT", "platt_b"))))
        else:
            iso = f[f.bloque == "ISOTONICA"].pivot_table(index="orden", columns="parametro", values="valor").sort_index()
            i = np.searchsorted(iso.x_lo.to_numpy(), pr, side="right") - 1
            ok = (i >= 0) & (pr < iso.x_hi.to_numpy()[np.clip(i, 0, None)])
            i = np.clip(i, 0, None)
            xl, xh, yl, yh = (iso[col].to_numpy()[i] for col in ("x_lo", "x_hi", "y_lo", "y_hi"))
            pd_cal = np.where(ok, yl + (yh - yl) * (pr - xl) / (xh - xl), np.nan)
        pd_cal = clip(pd_cal, "pd_cal_min", "pd_cal_max")
        z = norm.ppf(pd_cal) + (v("ANCLA", "delta") + v("ANCLA", "ajuste", 0.0))
        pit = p["modelo_macro"] is not None
        rho, lam = (v("VASICEK", "rho"), v("VASICEK", "lambda")) if pit else (np.zeros(n), np.zeros(n))
        den = np.sqrt(1.0 - rho)

        def pd_macro(fx, lx):
            x = (z - np.sqrt(rho) * lx * fx) / den if esq["convencion_macro"] == "VASICEK" else (z + lx * fx) / den
            return clip(norm.cdf(x), "pd_final_min", "pd_final_max")

        cero = np.zeros(n)
        if pit:
            x_mes = [ds[slot_mes(j)].to_numpy(dtype="float64") for j in p["variables"]]
            x_frz = [ds[slot_freeze(j)].to_numpy(dtype="float64") for j in p["variables"]]
            f_cur, f_frz = factor(m, nombre, x_mes), factor(m, nombre, x_frz)
            pd_cur, pd_frz = pd_macro(f_cur, lam), pd_macro(f_frz, lam)
        else:
            f_cur = f_frz = np.full(n, np.nan)
            pd_cur = pd_frz = pd_macro(cero, cero)
        pd_sm = pd_macro(cero, cero)
        esc, red = esq["escala_puntuacion"], esq["redondeo"]
        valores = [f_cur, f_frz, pd_cur, _redondear((1.0 - pd_cur) * esc, red), pd_frz,
                   _redondear((1.0 - pd_frz) * esc, red), pd_sm, _redondear((1.0 - pd_sm) * esc, red)]
        if p["sufijo"] == "EXTRA":
            for col, x in zip(EXTRAS, valores):
                scr[col] = [repr(float(y)) for y in x]
        else:
            for col, x in zip(BLOQUE, valores):
                scr[col + p["sufijo"]] = x
    return scr

def resumen(m):
    out = {"modelo": m.modelo, "id_calibracion": m.id_calibracion, "fecha": m.fecha, "productos": {}}
    for nombre, p in m.productos.items():
        out["productos"][nombre] = {"sufijo": p["sufijo"], "variables": p["variables"], "modelo_macro": p["modelo_macro"],
                                    "n_coeficientes_pd": int(len(p["filas"]))}
    return out




# ---------------------------------------------------------------- utilitarios
def _val(n, x):
    return n if pd.notna(n) else x


def _esquema(f):
    e = f[f.bloque == "ESQUEMA"]
    return {q: _val(n, x) for q, n, x in zip(e.parametro, e.valor, e.valor_txt)}


def _rho_unico(f):
    r = f[(f.bloque == "VASICEK") & (f.parametro == "rho")].valor.unique()
    if len(r) != 1:
        raise ValueError("el f_t Vasicek necesita un solo rho por producto")
    return float(r[0])


def _llaves_cliente(df, esq):
    k = {}
    for j, ll in enumerate(LLAVES, start=1):
        s = esq.get(f"slot_llave_{j:02d}")
        k[ll] = df[f"var_driver_{int(s):02d}"].astype(str).to_numpy() if s is not None else None
    s = esq.get("slot_clean")
    k["llave_clean"] = df[f"flg_clean_{int(s):02d}"].astype(str).to_numpy() if s is not None else None
    return k


def _resolver(f, bloque, parametro, k, n, defecto=np.nan):
    g = f[(f.bloque == bloque) & (f.parametro == parametro)]
    out = np.full(n, defecto, dtype="float64")
    if g.empty:
        return out
    g = g.assign(esp=(g[LLAVES + ["llave_clean"]] != COMODIN).sum(1)).sort_values("esp", ascending=False)
    hecho = np.zeros(n, dtype=bool)
    for _, r in g.iterrows():
        m = ~hecho
        for ll in LLAVES + ["llave_clean"]:
            if r[ll] != COMODIN:
                m &= k[ll] == r[ll]
        out[m] = r.valor
        hecho |= m
    return out


def _redondear(x, modo):
    return np.round(x) if modo == "HALF_EVEN" else np.sign(x) * np.floor(np.abs(x) + 0.5)
