""" Inference de calibracion: lee el ds (t_cal_<modelo>_rsk), carga los parametros del pkl y CALCULA el scr.
Las funciones (TTC, f_t, PIT, freeze) estan en utils/calculo.py; el pkl solo trae datos.
No lee la tabla de parametros: la x congelada ya viene en el ds. """

import argparse
import os
import pickle
import sys

import pandas as pd

from utils import calculo as C

DIR_DATA = os.environ.get("DIR_DATA", "/opt/ml/processing/input/data")
DIR_MODELS = os.environ.get("DIR_MODELS", "/opt/ml/processing/input/models")
DIR_RESULTS = os.environ.get("DIR_RESULTS", "/opt/ml/processing/output")


def detener(msg):
    print(f"Detenido: {msg}")
    sys.exit(1)


def main(args):
    ruta = os.path.join(DIR_MODELS, "objeto_calibracion.pkl")
    if not os.path.exists(ruta):
        detener("no hay pkl de calibracion")
    with open(ruta, "rb") as f:
        modelo = pickle.load(f)
    if modelo.modelo != args.model:
        detener(f"el pkl es de {modelo.modelo}, no de {args.model}")
    err = C.validar(modelo)
    if err:
        detener("; ".join(err))
    ds = pd.read_parquet(os.path.join(DIR_DATA, "ds.parquet"))
    for p in modelo.productos.values():
        for k in p["variables"]:
            for c in (f"var_macro_{2 * k - 1:02d}", f"var_macro_{2 * k:02d}"):
                if ds[c].isna().any():
                    detener(f"{c} vacio en el ds")
    scr = C.calcular(modelo, ds)
    scr.to_parquet(os.path.join(DIR_RESULTS, f"{args.table_score}_{args.partition}.parquet"), index=False)
    print(f"OK {len(scr)} filas | {modelo.id_calibracion}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", type=str)
    parser.add_argument("--table-score", type=str)
    parser.add_argument("--partition", type=str)
    main(parser.parse_args())
