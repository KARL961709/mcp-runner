"""Genera t_mst_denton_pesos_rsk: pesos fijos para desagregar a mensual la inflacion 12m trimestral
de APOYO con Denton aditivo (primeras diferencias), anclado al observado del BCRP.

Para un cod_mes t corrido de a uno, la x del VC es MA3 de la inflacion 12m (t-2..t). Si k meses de esa
ventana no estan publicados (k = t - ultimo observado, 1 o 2), la x es una combinacion lineal FIJA de:
  OBS  rel = j : inflacion 12m observada en (ultimo_observado - j), j = 0..N_ANCLA-1
  TRIM rel = r : valor APOYO del trimestre que cierra en ultimo_observado + e0 + 3r
                 (e0 = 3 - fase si fase > 0; 3 si fase = 0)
fase = meses del trimestre en curso ya observados: 1 si el ultimo observado es el 1er mes del trimestre,
       2 si es el 2do, 0 si es cierre de trimestre.
variante: CON_TRIM_CURSO exige que el trimestre en curso promedie APOYO; SIN_TRIM_CURSO solo exige los
          trimestres futuros completos (recomendada, pendiente de decision).

Uso: python generar_pesos.py  -> escribe t_mst_denton_pesos_rsk.csv y corre su autoprueba.
"""
import os
import sys

import numpy as np
import pandas as pd

N_ANCLA, N_TRIM = 6, 6
AQUI = os.path.dirname(os.path.abspath(__file__))


def estructura(fase, variante):
    """Matriz W tal que serie_mensual = W @ b, con b = [anclas (antigua -> reciente); trimestres incluidos]."""
    s0 = N_ANCLA - fase if fase else N_ANCLA          # primer mes del trimestre r = 0
    n = s0 + 3 * N_TRIM
    filas, rel_trim = [], []
    for j in range(N_ANCLA):
        r = np.zeros(n)
        r[j] = 1
        filas.append(r)
    for q in range(N_TRIM):
        if q == 0 and fase and variante == "SIN_TRIM_CURSO":
            continue
        r = np.zeros(n)
        r[s0 + 3 * q: s0 + 3 * q + 3] = 1 / 3
        filas.append(r)
        rel_trim.append(q)
    C = np.array(filas)
    D = np.diff(np.eye(n), axis=0)
    m = len(C)
    K = np.block([[2 * D.T @ D, C.T], [C, np.zeros((m, m))]])
    W = np.linalg.solve(K, np.r_[np.zeros((n, m)), np.eye(m)])[:n]
    return W, rel_trim


def pesos():
    out = []
    for variante in ("SIN_TRIM_CURSO", "CON_TRIM_CURSO"):
        for fase in (0, 1, 2):
            W, rel_trim = estructura(fase, variante)
            ult = N_ANCLA - 1
            for k in (1, 2):
                fila = W[ult + k - 2: ult + k + 1].mean(axis=0)     # x(t) = MA3 de t-2..t
                for j in range(N_ANCLA):
                    out.append((variante, fase, k, "OBS", j, float(fila[N_ANCLA - 1 - j])))
                for i, q in enumerate(rel_trim):
                    out.append((variante, fase, k, "TRIM", q, float(fila[N_ANCLA + i])))
    return pd.DataFrame(out, columns=["variante", "fase", "k", "origen", "rel", "peso"])


def denton_directo(obs, trims, fase, variante):
    """Resuelve Denton con los datos (sin pesos). obs: anclas antigua->reciente; trims: {r: valor}."""
    s0 = N_ANCLA - fase if fase else N_ANCLA
    n = s0 + 3 * N_TRIM
    C, b = [], []
    for j, v in enumerate(obs):
        r = np.zeros(n); r[j] = 1; C.append(r); b.append(v)
    for q, v in trims.items():
        if q == 0 and fase and variante == "SIN_TRIM_CURSO":
            continue
        r = np.zeros(n); r[s0 + 3 * q: s0 + 3 * q + 3] = 1 / 3; C.append(r); b.append(v)
    C, b = np.array(C), np.array(b)
    D = np.diff(np.eye(n), axis=0)
    K = np.block([[2 * D.T @ D, C.T], [C, np.zeros((len(b), len(b)))]])
    return np.linalg.solve(K, np.r_[np.zeros(n), b])[:n]


def autoprueba(P):
    rng = np.random.default_rng(1)
    peor = 0.0
    for _ in range(50):
        obs = list(3 + rng.normal(0, 0.5, N_ANCLA))
        trims = {q: float(3 + rng.normal(0, 1)) for q in range(N_TRIM)}
        for variante in ("SIN_TRIM_CURSO", "CON_TRIM_CURSO"):
            for fase in (0, 1, 2):
                serie = denton_directo(obs, trims, fase, variante)
                for k in (1, 2):
                    t = N_ANCLA - 1 + k
                    x_dir = serie[t - 2: t + 1].mean()
                    p = P[(P.variante == variante) & (P.fase == fase) & (P.k == k)]
                    x_pes = sum(r.peso * (obs[N_ANCLA - 1 - r.rel] if r.origen == "OBS" else trims[r.rel]) for r in p.itertuples())
                    peor = max(peor, abs(x_pes - x_dir))
    sumas = P.groupby(["variante", "fase", "k"]).peso.sum()
    return peor, float(sumas.min()), float(sumas.max())


if __name__ == "__main__":
    P = pesos()
    peor, smin, smax = autoprueba(P)
    print(f"{len(P)} filas | pesos vs Denton directo (50 casos x 2 variantes x 3 fases x k=1,2): dif max {peor:.1e}"
          f" | suma de pesos por caso en [{smin:.12f}, {smax:.12f}]")
    if peor > 1e-10 or abs(smin - 1) > 1e-10 or abs(smax - 1) > 1e-10:
        sys.exit("FALLA la autoprueba")
    P["peso"] = [repr(v) for v in P.peso]
    P.to_csv(os.path.join(AQUI, "t_mst_denton_pesos_rsk.csv"), sep=";", index=False)
    print("OK -> t_mst_denton_pesos_rsk.csv")
