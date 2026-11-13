"""Implementacion de REFERENCIA (Python) de lo que hace el inference.sql de t_cal_<modelo>_rsk.
El SQL de Athena (sql/) debe dar EXACTAMENTE lo mismo: usar esto para validar su salida.

Logica (vive en el SQL, no en la tabla de parametros): serie, transformacion, ventana, mezcla de fuentes.
Unico parametro: cod_mes_freeze (t_cal_parametros_rsk). La x congelada se LEE del ds del mes de freeze.
Mezcla de fuentes (VC): observado BCRP manda; si faltan meses de la ventana, Denton con pesos fijos.
"""
import os

import numpy as np
import pandas as pd

AQUI = os.path.dirname(os.path.abspath(__file__))
COL_PAR = ["modelo", "parametro", "valor", "nro_carga", "ts_carga", "p_codmes"]
COL_DS = (["cod_mes", "cod_tip_doc", "key_value", "cod_cli", "prob_modelo", "puntuacion"]
          + [f"var_macro_{i:02d}" for i in range(1, 13)] + [f"var_driver_{i:02d}" for i in range(1, 13)]
          + [f"flg_clean_{i:02d}" for i in range(1, 5)] + ["ts_carga", "p_codmes", "p_fecdia"])
CATALOGO = {"cod_mes_freeze"}
VARIANTE_DENTON = "SIN_TRIM_CURSO"     # pendiente de decision del owner (ver LEEME)


def mi(c):
    c = str(c)
    return int(c[:4]) * 12 + int(c[4:6]) - 1


def cm(i):
    return f"{i // 12}{i % 12 + 1:02d}"


# ---------------------------------------------------------------- tabla de parametros
def validar_parametros(par):
    err = []
    if par.duplicated(["modelo", "parametro", "nro_carga", "p_codmes"]).any():
        err.append("LLAVE: filas repetidas en (modelo, parametro, nro_carga, p_codmes)")
    fuera = sorted(set(par.parametro) - CATALOGO)
    if fuera:
        err.append(f"PARAMETRO fuera de catalogo: {fuera}")
    f = par[par.parametro == "cod_mes_freeze"].valor.astype(str)
    if (~f.str.fullmatch(r"20\d{2}(0[1-9]|1[0-2])")).any():
        err.append("VALOR: cod_mes_freeze invalido")
    return err


def vigente(par, modelo, cod_mes, ts=None):
    """Mayor p_codmes <= cod_mes del modelo y, dentro, mayor nro_carga (solo cargas con ts_carga <= ts)."""
    r = par[(par.modelo == modelo) & (par.p_codmes.astype(str) <= str(cod_mes))]
    if ts is not None:
        r = r[r.ts_carga <= ts]
    if r.empty:
        raise ValueError(f"sin carga vigente de {modelo} para {cod_mes}")
    r = r[r.p_codmes == r.p_codmes.max()]
    r = r[r.nro_carga == r.nro_carga.max()]
    return r.set_index("parametro").valor.to_dict()


# ---------------------------------------------------------------- macro
def var12m(porc_ipc):
    """porc_ipc: {cod_mes: var% mensual}. Inflacion 12m compuesta, exige los 12 meses."""
    s = {mi(c): float(v) for c, v in porc_ipc.items()}
    out = {}
    for i in s:
        x = np.array([s[j] for j in range(i - 11, i + 1) if j in s])
        if len(x) == 12:
            out[cm(i)] = 100.0 * (np.exp(np.sum(np.log(1.0 + x / 100.0))) - 1.0)
    return out


def x_ree(porc_ipc, t):
    """REE: promedio de porc_ipc de t-11 a t-6 (exige los 6). Siempre observado (k = 0)."""
    s = {mi(c): float(v) for c, v in porc_ipc.items()}
    x = np.array([s[j] for j in range(mi(t) - 11, mi(t) - 5) if j in s])
    return float(np.mean(x)) if len(x) == 6 else np.nan


def pesos_denton():
    P = pd.read_csv(os.path.join(AQUI, "..", "denton", "t_mst_denton_pesos_rsk.csv"), sep=";", dtype={"peso": str})
    P["peso"] = [float(v) for v in P.peso]
    return P


def x_vc(porc_ipc, apoyo_base, t, P=None):
    """VC: x(t) = MA3 de la inflacion 12m (t-2..t). Observado manda; meses faltantes con Denton.
    apoyo_base: {cod_mes_cierre_trimestre: inflacion 12m promedio del trimestre} (macro_apoyo_proy, BASE)."""
    v12 = var12m(porc_ipc)
    obs = [c for c in v12 if c <= t]
    if not obs:
        return np.nan, None
    ult = max(obs)
    k = mi(t) - mi(ult)
    if k == 0:
        return float(np.mean([v12[cm(mi(t) - j)] for j in (2, 1, 0)])), 0
    if k > 2:
        raise ValueError(f"{t}: {k} meses sin observado; el diseno cubre k = 1 o 2")
    P = pesos_denton() if P is None else P
    pos = mi(ult) % 3 + 1
    fase = pos % 3
    e0 = 3 - fase if fase else 3
    p = P[(P.variante == VARIANTE_DENTON) & (P.fase == fase) & (P.k == k)]
    x = 0.0
    for r in p.itertuples():
        if r.origen == "OBS":
            v = v12[cm(mi(ult) - r.rel)]
        else:
            cierre = cm(mi(ult) + e0 + 3 * r.rel)
            if cierre not in apoyo_base:
                raise ValueError(f"falta APOYO del trimestre {cierre}")
            v = apoyo_base[cierre]
        x = x + r.peso * v
    return x, k


LOGICA = {"cppibkren": lambda ipc, apoyo, t: [x_ree(ipc, t)],
          "vcadmbnk": lambda ipc, apoyo, t: [x_vc(ipc, apoyo, t)[0]]}


# ---------------------------------------------------------------- ds
def armar_ds(modelo, t, clientes, porc_ipc, apoyo_base, par, hist, ts):
    """clientes: llaves + prob_modelo + puntuacion + var_driver_NN + flg_clean_NN (drivers = logica del SQL).
    hist: {cod_mes: ds ya escrito} -> de ahi sale la x congelada."""
    cf = str(vigente(par, modelo, t, ts)["cod_mes_freeze"])
    x_t = LOGICA[modelo](porc_ipc, apoyo_base, t)
    if cf == t:
        x_f = x_t
    elif cf in hist:
        x_f = [float(hist[cf][f"var_macro_{2 * k - 1:02d}"].iloc[0]) for k in range(1, len(x_t) + 1)]
    else:
        raise ValueError(f"no existe el ds del mes de freeze {cf}")
    ds = pd.DataFrame(index=clientes.index)
    for c in COL_DS:
        ds[c] = clientes[c] if c in clientes else None
    ds["cod_mes"], ds["p_codmes"], ds["p_fecdia"], ds["ts_carga"] = t, t, t + "15", ts
    for k, (a, b) in enumerate(zip(x_t, x_f), start=1):
        ds[f"var_macro_{2 * k - 1:02d}"] = a
        ds[f"var_macro_{2 * k:02d}"] = b
    for i in range(1, 13):
        ds[f"var_macro_{i:02d}"] = ds[f"var_macro_{i:02d}"].astype("float64")
    return ds[COL_DS]
