""" Inferencia del modelo """

import sys
import subprocess

subprocess.check_call(
    [sys.executable, "-m", "pip", "install", "catboost==1.2.10", "scikit-learn==1.7.2"]
)

# pylint: disable=E0401,C0411,C0413
import numpy as np

np.float = float

import argparse
import datetime
import pytz
import pandas as pd
import pickle
# Start: Add Calibration
import json
from scipy.stats import norm
# End: Add Calibration

from utils.utils import read_data
from utils.utils import metrics_stability

# pylint: disable=E0401,C0411,C0413

# RUTAS DE ENTRADA =================================================================================

DIR_DATA = "/opt/ml/processing/input/data"
DIR_MODELS = "/opt/ml/processing/input/models"
DIR_RENAME = "/opt/ml/processing/input/rename"

# RUTAS DE SALIDA ==================================================================================

DIR_RESULTS = "/opt/ml/processing/output/results"

# LISTA DE VARIABLES ===============================================================================

COLS_IDS = ["cod_mes", "cod_tip_doc", "key_value", "cod_cli"]

COLS_VARS = [
    'avg_dda_tlc_12m',
    'rat_miemsup2r',
    'cnt_gestiones_6m',
    'std_datraso_rd_u1a',
    'num_inc_sld_tip_pas_12m',
    'max_clfibk_06m',
    'rat_sld_pp_u1m_tc_ibk',
    'flg_labdp',
    'avg_decrsld12m',
    'cnt_deccorreg_12m',
    'max_dias_atraso_no_ibk_3m',
    'avg_diamorasldppibk_12m',
    'mto_dda_otr_emp_12m',
    'ant_profesional',
    'mto_totalrec06m',
    'rat_maxsldppibk_03m',
    'rat_comparacion_u1m_u12m',
    'ant_primer_producto',
    'min_pasctasld_12m',
    'avg_slddispefpn_u6m',
    'sld_beta_pc_pp_1a',
    'num_vehiculos',
    'num_edad',
    'var_ent_dist_rd_1a',
    'max_dda_pp_rat_9m',
    'rat_actpas_03m',
    'avg_rat_dispefpnj_u1a',
    'num_titulo_prof',
    'rat_saldo_rt_t1_t12',
    'porc_max_sldrsg_06m',
    'cnt_dectctotal_12m',
    'flg_pasibk',
    'porc_avg_sld_rd_6m',
    'med_sld_sa_hip_3i_6m',
    'cnt_atraso_01_aj',
    'num_inmuebles',
    'avg_trxtot12m',
    'porc_avg_pctusotctot_u1a',
    'cnt_dias_adelanto_atraso',
    'cnt_mespeornorssff_12m',
    'rat_svotrppeallsf_3m',
    'med_dec_sld_tarj_3i_6m',
    'trf_mtomax_grifos_pos12m',
    'trf_far_mtomax_med_12m',
    'trf_mtot_tc_retail_pos1m',
    'trf_prm_restaur_pos_6m',
    'trf_mtoprm_altagama_12m',
    'trf_mto_salud_u24m',
]

COLS_CAT = {
    "global": [
        'flg_pasibk',
         'flg_labdp',
         'trf_mtoprm_altagama_12m',
         'trf_mtomax_grifos_pos12m',
         'trf_mtot_tc_retail_pos1m',
         'trf_far_mtomax_med_12m',
         'trf_mto_salud_u24m',
         'trf_prm_restaur_pos_6m',
    ],
}

COLS_CONT = {
    "global": [
        'avg_dda_tlc_12m',
        'rat_miemsup2r',
        'cnt_gestiones_6m',
        'std_datraso_rd_u1a',
        'num_inc_sld_tip_pas_12m',
        'max_clfibk_06m',
        'rat_sld_pp_u1m_tc_ibk',
        'avg_decrsld12m',
        'cnt_deccorreg_12m',
        'max_dias_atraso_no_ibk_3m',
        'avg_diamorasldppibk_12m',
        'mto_dda_otr_emp_12m',
        'ant_profesional',
        'mto_totalrec06m',
        'rat_maxsldppibk_03m',
        'rat_comparacion_u1m_u12m',
        'ant_primer_producto',
        'min_pasctasld_12m',
        'avg_slddispefpn_u6m',
        'sld_beta_pc_pp_1a',
        'num_vehiculos',
        'num_edad',
        'var_ent_dist_rd_1a',
        'max_dda_pp_rat_9m',
        'rat_actpas_03m',
        'avg_rat_dispefpnj_u1a',
        'num_titulo_prof',
        'rat_saldo_rt_t1_t12',
        'porc_max_sldrsg_06m',
        'cnt_dectctotal_12m',
        'porc_avg_sld_rd_6m',
        'med_sld_sa_hip_3i_6m',
        'cnt_atraso_01_aj',
        'num_inmuebles',
        'avg_trxtot12m',
        'porc_avg_pctusotctot_u1a',
        'cnt_dias_adelanto_atraso',
        'cnt_mespeornorssff_12m',
        'rat_svotrppeallsf_3m',
        'med_dec_sld_tarj_3i_6m',
    ],
}

COLS_NULL = {
    'flg_pasibk': 0,
    'flg_labdp': 0,
    'trf_mtoprm_altagama_12m': 0,
    'trf_mtomax_grifos_pos12m': 0,
    'trf_mtot_tc_retail_pos1m': 0,
    'trf_far_mtomax_med_12m': 0,
    'trf_mto_salud_u24m': 0,
    'trf_prm_restaur_pos_6m': 0,
}

COLS_DTYPES = {
    "avg_dda_tlc_12m": "float64",
    "rat_miemsup2r": "float64",
    "cnt_gestiones_6m": "float64",
    "std_datraso_rd_u1a": "float64",
    "num_inc_sld_tip_pas_12m": "float64",
    "max_clfibk_06m": "float64",
    "rat_sld_pp_u1m_tc_ibk": "float64",
    "flg_labdp": "int64",
    "avg_decrsld12m": "float64",
    "cnt_deccorreg_12m": "float64",
    "max_dias_atraso_no_ibk_3m": "float64",
    "avg_diamorasldppibk_12m": "float64",
    "mto_dda_otr_emp_12m": "float64",
    "ant_profesional": "float64",
    "mto_totalrec06m": "float64",
    "rat_maxsldppibk_03m": "float64",
    "rat_comparacion_u1m_u12m": "float64",
    "ant_primer_producto": "float64",
    "min_pasctasld_12m": "float64",
    "avg_slddispefpn_u6m": "float64",
    "sld_beta_pc_pp_1a": "float64",
    "num_vehiculos": "float64",
    "num_edad": "float64",
    "var_ent_dist_rd_1a": "float64",
    "max_dda_pp_rat_9m": "float64",
    "rat_actpas_03m": "float64",
    "avg_rat_dispefpnj_u1a": "float64",
    "num_titulo_prof": "float64",
    "rat_saldo_rt_t1_t12": "float64",
    "porc_max_sldrsg_06m": "float64",
    "cnt_dectctotal_12m": "float64",
    "flg_pasibk": "int64",
    "porc_avg_sld_rd_6m": "float64",
    "med_sld_sa_hip_3i_6m": "float64",
    "cnt_atraso_01_aj": "float64",
    "num_inmuebles": "float64",
    "avg_trxtot12m": "float64",
    "porc_avg_pctusotctot_u1a": "float64",
    "cnt_dias_adelanto_atraso": "float64",
    "cnt_mespeornorssff_12m": "float64",
    "rat_svotrppeallsf_3m": "float64",
    "med_dec_sld_tarj_3i_6m": "float64",
    "trf_mtomax_grifos_pos12m": "int64",
    "trf_far_mtomax_med_12m": "int64",
    "trf_mtot_tc_retail_pos1m": "int64",
    "trf_prm_restaur_pos_6m": "int64",
    "trf_mtoprm_altagama_12m": "int64",
    "trf_mto_salud_u24m": "int64"
}

# PREPROCESAR LOS DATOS DE ENTRADA =================================================================

def preprocessing_fn(
    df: pd.DataFrame, 
    cols_null: dict = COLS_NULL, 
    cols_dtypes: dict = COLS_DTYPES
) -> tuple[pd.DataFrame, pd.DataFrame]:
    """
    Preprocesa los datos de entrada.
    ### Parametros
    - df: Datos de entrada cargados.
    - cols_null: Valores para rellenar nulos: {'col1': 0.0, 'col2': -999.0}
    - cols_dtypes: Tipos de datos de las columnas: {'col1': int, 'col2': float}
    ### Retorna
    - df: Datos preprocesados.
    - df_null: Datos preprocesados con valores nulos.
    """
    # Restablece el índice para evitar descalces de longitud si vienen índices duplicados
    df = df.reset_index(drop=True)

    print("=== Tipos de datos originales (Entrada) ===")
    print(df.dtypes)

    # 1. Copia con nulos originales
    df_null = df.copy()

    # 2. Imputación de nulos específicos
    df = df.fillna(cols_null)
    
    print("=== Variables seleccionadas ===")
    print(COLS_VARS)
    
    # 3. Casteo de tipos según el diccionario
    df = df.astype(cols_dtypes)

    print("\n=== Tipos de datos finales (Preprocesados) ===")
    print(df.dtypes)

    return df, df_null


# HACER LA INFERENCIA DEL MODELO ===================================================================


def inference_fn(dir_models: str, df: pd.DataFrame, cols_vars: list) -> pd.DataFrame:
    """
    Hace la inferencia del modelo.
    ### Parametros
    - dir_models: Carpeta con el modelo entrenado.
    - df: Datos preprocesados.
    - cols_vars: Columnas que son variables.
    ### Retorna
    - df: Datos preprocesados con la prediccion del modelo.
    """

    path = f"{dir_models}/objeto_modelo_v2.pkl" #revisar si cambia el nombre del modelo
    with open(path, "rb") as f:
        model = pickle.load(f)

    # 2. Diccionario de mapeo: Nombre Nuevo (en df) -> Nombre Antiguo (que conoce el modelo)
    map_nuevo_a_antiguo = {
        "porc_max_sldrsg_06m": "porc_max_sldrsg_03m",
        "min_pasctasld_12m": "min_pasctasld_03m",
    }

    # 3. Crear matriz temporal X renombrada SOLO para la inferencia
    # Agregamos .copy() para garantizar un DataFrame independiente en memoria
    X_inferencia = df[COLS_VARS].copy().rename(columns=map_nuevo_a_antiguo)

    # 4. Asignar la probabilidad de vuelta en el DataFrame original (que conserva sus nombres nuevos)
    df_out = df.copy()
    df_out["probability"] = model.predict_proba(X_inferencia)[:, 1].round(9)

    return df_out


# POSTPROCESAR LA INFERENCIA DEL MODELO ============================================================


# Start: Add Calibration
def load_calib(dir_models: str) -> dict:
    """Carga el artefacto de coeficientes de calibracion (models/calibracion_ree.json)."""
    with open(f"{dir_models}/calibracion_ree.json", "r", encoding="utf-8") as f:
        return json.load(f)
# End: Add Calibration


def postprocessing_fn(df: pd.DataFrame, calib: dict) -> pd.DataFrame:
    """
    Postprocesa la inferencia: score crudo + calibracion PIT (lambda=1) y TTC (lambda=0).
    Cadena (entrega_ree/outputs_v5, reproduce ree_scoring/71):
      pd_cal = sigmoid(m + a*ln p - b*ln(1-p))
      z      = Phi^-1(pd_cal) + delta_seg + delta_0
      prob_modelo_cal     = Phi((z - sqrt(rho)*lambda*f_t)/sqrt(1-rho))
      prob_modelo_cal_ttc = Phi( z /sqrt(1-rho))   (lambda=0)
    """
    df["score"] = ((1 - df["probability"]) * 1000).round(0)

    # Start: Add Calibration
    seg_col = calib["segment_col"]
    lo9, hi9 = calib["clip_pd_cal"]
    lo4, hi4 = calib["clip_pd_final"]
    rho, lam, d0 = calib["rho"], calib["lambda"], calib["delta_0"]
    sq_rho, sq_1mrho = np.sqrt(rho), np.sqrt(1.0 - rho)

    p = np.clip(df["probability"].to_numpy(dtype="float64"), 1e-9, 1.0 - 1e-9)
    lnp, ln1p = np.log(p), np.log(1.0 - p)
    seg = df[seg_col].astype(str).to_numpy()
    f_t = pd.to_numeric(df[calib["f_t_col"]], errors="coerce").to_numpy(dtype="float64")

    z_ttc = np.full(len(p), np.nan)
    for s, c in calib["segments"].items():
        mk = seg == s
        z_beta = c["m"] + c["a"] * lnp[mk] - c["b"] * ln1p[mk]
        pd_cal = np.clip(1.0 / (1.0 + np.exp(-z_beta)), lo9, hi9)
        z_ttc[mk] = norm.ppf(pd_cal) + c["probit_delta"] + d0

    pd_pit = np.clip(norm.cdf((z_ttc - sq_rho * lam * f_t) / sq_1mrho), lo4, hi4)
    pd_ttc = np.clip(norm.cdf(z_ttc / sq_1mrho), lo4, hi4)

    df["prob_modelo_cal"] = pd_pit
    df["puntuacion_cal"] = np.round((1.0 - pd_pit) * 1000.0, 0)
    df["prob_modelo_cal_ttc"] = pd_ttc
    # End: Add Calibration

    return df


# FORMATEAR LOS DATOS DE SALIDA ====================================================================


def output_fn(df: pd.DataFrame, cols_vars: list = None) -> pd.DataFrame:
    """
    Formatea los datos de salida.
    ### Parametros
    - df: Datos preprocesados con la prediccion postprocesada del modelo.
    - cols_vars: Columnas que son variables.
    ### Retorna
    - df_output: Datos formateados de salida.
    """

    datetime_now = datetime.datetime.now(pytz.timezone("America/Lima"))
    datetime_now = datetime_now.strftime("%Y%m%d")

    df_output = pd.DataFrame()
    df_output["cod_mes"] = df["cod_mes"]
    df_output["key_value"] = df["key_value"]
    df_output["cod_tip_doc"] = df["cod_tip_doc"]
    df_output["cod_cli"] = df["cod_cli"]
    df_output["prob_modelo"] = df["probability"]
    df_output["puntuacion"] = df["score"]
    df_output["modelo"] = "CompPP Reenganche"
    df_output["ts_carga"] = datetime_now
    df_output["grupo_ejec"] = ""
    df_output["segmento"] = ""
    df_output["orden"] = ""
    # Start: Add Calibration
    df_output["grupo_calibracion"] = ""                 # vacio; el segmento es interno (elige la BetaCal)
    df_output["prob_modelo_cal"] = df["prob_modelo_cal"]
    df_output["puntuacion_cal"] = df["puntuacion_cal"]
    df_output["extra_01"] = df["prob_modelo_cal_ttc"]   # prob_modelo_cal_ttc (lambda=0)
    # End: Add Calibration
    df_output["extra_02"] = ""
    df_output["extra_03"] = ""
    df_output["extra_04"] = ""
    df_output["extra_05"] = ""

    for cols_var in cols_vars:
        df_output[f"woe_{cols_var}"] = df[cols_var]

    # Start: Add Calibration
    df_output["trf_macro01"] = df["trf_macro01"]   # f_t
    df_output["trf_macro02"] = df["trf_macro02"]   # macro transformada (AVG porc_ipc T-10..T-5)
    # End: Add Calibration
    df_output["p_codmes"] = df["cod_mes"]
    
    return df_output


# FUNCION PRINCIPAL ================================================================================


def main(args: argparse.Namespace) -> None:
    """Funcion principal"""

    model = args.model
    table_score = args.table_score
    partition = args.partition

    df = read_data(DIR_DATA, DIR_RENAME)

    df, df_null = preprocessing_fn(df, COLS_NULL, COLS_DTYPES)

    # Start: Add Calibration
    calib = load_calib(DIR_MODELS)
    # End: Add Calibration
    df = inference_fn(DIR_MODELS, df, COLS_VARS)
    df = postprocessing_fn(df, calib)
    df_output = output_fn(df, COLS_VARS)

    path = f"{DIR_RESULTS}/{table_score}_{partition}.txt"
    df_output.to_csv(path, index=False, sep="|")

    cols = [f"woe_{c}" for c in COLS_VARS]
    df_output = df_output.drop(cols, axis=1)

    path = f"{DIR_RESULTS}/{table_score}_tdt_{partition}.txt"
    df_output.to_csv(path, index=False, sep="|")

    var_segmentos = ""
    df_null["puntuacion"] = df_output["puntuacion"]  # pylint: disable=E1136
    df_metrics = metrics_stability(df_null, COLS_CAT, COLS_CONT, var_segmentos)

    path = f"{DIR_RESULTS}/t_est_{model}_rsk_{partition}.txt"
    df_metrics.to_csv(path, index=False, sep="|")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", type=str)
    parser.add_argument("--table-score", type=str)
    parser.add_argument("--partition", type=str)
    main(parser.parse_args())
