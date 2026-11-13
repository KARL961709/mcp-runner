"""Arma el pkl de parametros de calibracion desde su especificacion JSON (solo datos, sin codigo propio).

El pkl es un SimpleNamespace con: modelo, id_calibracion, fecha, productos.
Cada producto: sufijo ('_pp', '_tc'... o 'EXTRA'), variables ([k]), modelo_macro (dict o None)
y filas (DataFrame con los coeficientes TTC por celda: ESQUEMA, BETA/PLATT/ISOTONICA, ANCLA, VASICEK, CLIP).
Las funciones que lo aplican viven en mlops/scripts/utils/calculo.py (codigo del inference.py).

Uso: python armar_pkl.py spec_<id_calibracion>.json [carpeta_salida]
     -> <carpeta_salida>/objeto_calibracion.pkl  (nombre que espera el inference.py)
"""
import json
import os
import pickle
import sys
from types import SimpleNamespace

import pandas as pd

COLS = ["bloque", "parametro", "llave_01", "llave_02", "llave_03", "llave_04", "llave_clean", "orden", "valor", "valor_txt"]


def armar(ruta_spec):
    spec = json.load(open(ruta_spec, encoding="utf-8"))
    productos = {}
    for nombre, p in spec["productos"].items():
        filas = pd.DataFrame(p["filas"])[COLS]
        filas["valor"] = filas["valor"].astype("float64")
        productos[nombre] = {"sufijo": p["sufijo"], "variables": p["variables"], "modelo_macro": p["modelo_macro"], "filas": filas}
    return SimpleNamespace(modelo=spec["modelo"], id_calibracion=spec["id_calibracion"], fecha=spec["fecha"], productos=productos)


if __name__ == "__main__":
    salida = sys.argv[2] if len(sys.argv) > 2 else "."
    os.makedirs(salida, exist_ok=True)
    m = armar(sys.argv[1])
    with open(os.path.join(salida, "objeto_calibracion.pkl"), "wb") as f:
        pickle.dump(m, f)
    print(f"OK {m.id_calibracion}: {list(m.productos)}")
