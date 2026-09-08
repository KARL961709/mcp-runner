''' Utilidades para la inferencia '''

# pylint: disable=E0401,C0411,C0413
import numpy as np
np.float = float

import os
import glob
import json
import pytz
import pandas as pd
import dask.dataframe as dd

from datetime import datetime
# pylint: disable=E0401,C0411,C0413


def read_data(dir_data: str,
              dir_rename: str = None) -> pd.DataFrame:
    '''
    Carga los datos de entrada.
    ### Parametros
    - dir_data: Carpeta con los datos de entrada.
    - dir_rename: Carpeta con los nombres de columnas por renombrar.
    ### Retorna
    - df: Datos de entrada cargados.
    '''

    paths = glob.glob(f'{dir_data}/*.csv')
    paths += glob.glob(f'{dir_data}/*.txt')
    if paths:
        path = paths[0]
        sep = ',' if path[-4:] == '.csv' else '|'
        df = pd.read_csv(path, sep=sep)
    else:
        path = f'{dir_data}/*'
        df = dd.read_parquet(path)
        df = df.compute().reset_index(drop=True)

    if dir_rename and os.path.exists(dir_rename):
        paths = glob.glob(f'{dir_rename}/*.json')
        with open(paths[0], 'r', encoding='utf-8') as f:
            rename = json.load(f)

        rename = {k: v for k, v in rename.items() if k in df.columns}
        df = df.rename(rename, axis=1)

    return df


def metrics_cat(df: pd.DataFrame, cols: list, cod_mes: str) -> pd.DataFrame:
    '''
    Calcula metricas de variables categoricas.
    ### Parametros
    - df: Datos del modelo.
    - cols: Columnas de variables categoricas.
    - cod_mes: Periodo de los datos.
    ### Retorna
    - df_metrics: Metricas de variables categoricas.
    '''

    df_metrics = []
    for var_name in cols:
        df_m = df[var_name].value_counts(dropna=False)
        df_m = df_m.sort_index().reset_index()
        df_m.columns = ['estadistico', cod_mes]
        df_m['variable'] = var_name
        df_metrics.append(df_m)

    df_metrics = pd.concat(df_metrics)
    df_metrics['tip_metrica'] = 'count'
    df_metrics = df_metrics[['variable', 'estadistico', 'tip_metrica', cod_mes]]

    df_ratio = df_metrics.copy()
    df_ratio['tip_metrica'] = 'ratio'
    for var_name in cols:
        mask = df_metrics['variable'] == var_name
        total_count = df_metrics[mask][cod_mes].sum()
        df_ratio.loc[mask, cod_mes] = df_ratio.loc[mask, cod_mes] / total_count

    df_metrics = pd.concat([df_metrics, df_ratio])

    return df_metrics


def metrics_cont(df: pd.DataFrame, cols: list, cod_mes: str) -> pd.DataFrame:
    '''
    Calcula metricas de variables continuas.
    ### Parametros
    - df: Datos del modelo.
    - cols: Columnas de variables continuas.
    - cod_mes: Periodo de los datos.
    ### Retorna
    - df_estax: Metricas de variables continuas.
    '''

    df_infer_cont = df[cols].astype(float)
    dfc = df_infer_cont.describe().T
    dfc['NMISS'] = df_infer_cont.isna().sum()
    dfc.columns = ['N', 'Mean', 'Std', 'Min', 'Q1', 'Q2', 'Q3', 'MAX', 'NMISS']
    dfc['N'] = dfc['N'].astype(int)
    cf = ['N', 'NMISS', 'Mean', 'Std', 'Min', 'Q1', 'Q2', 'Q3', 'MAX']
    df_esta = dfc[cf].copy()
    df_estax = df_esta.unstack().reset_index()
    df_estax.columns = ['estadistico', 'variable', cod_mes]
    df_estax['tip_metrica'] = 'continuo'
    df_estax = df_estax.sort_values(['variable', 'estadistico'])
    df_estax = df_estax[['variable', 'estadistico', 'tip_metrica', cod_mes]]

    return df_estax


def metrics_stability(df: pd.DataFrame,
                      cols_cat: dict,
                      cols_cont: dict,
                      var_segmentos: str = None) -> pd.DataFrame:
    '''
    Calcula métricas de estabilidad por segmentos.
    ### Parámetros
    - df: Datos del modelo.
    - cols_cat: Diccionario de variables categóricas por segmento.
    - cols_cont: Diccionario de variables continuas por segmento.
    - var_segmentos: Columna que define los segmentos.
    ### Retorna
    - df_metrics: Métricas de estabilidad por segmentos.
    '''

    cod_mes = df['cod_mes'].values[0]
    segmentos = ['global'] if not var_segmentos else df[var_segmentos].unique()

    df_metrics = []
    for segmento in segmentos:
        df_segmento = df if segmento == 'global' else df[df[var_segmentos] == segmento]

        # Calcular metricas para el segmento
        cols_cat_seg = cols_cat[f'{segmento}']
        df_cat = metrics_cat(df_segmento, cols_cat_seg, cod_mes)
        mask = df_cat['variable'] == 'deciles'
        df_cat.loc[mask, 'variable'] = 'pd.cut'

        cols_cont_seg = cols_cont[f'{segmento}']
        df_cont = metrics_cont(df_segmento, cols_cont_seg, cod_mes)

        datetime_now = datetime.now(pytz.timezone('America/Lima'))
        datetime_now = datetime_now.strftime('%Y%m%d')

        df_metrics_seg = pd.concat([df_cat, df_cont])
        df_metrics_seg['cod_mes'] = cod_mes
        df_metrics_seg['flg_segmento'] = segmento if segmento != 'global' else ''
        df_metrics_seg['condicion'] = ''
        df_metrics_seg['valor'] = df_metrics_seg[cod_mes].copy()
        df_metrics_seg['fec_carga'] = datetime_now
        df_metrics_seg['extra_01'] = ''
        df_metrics_seg['extra_02'] = ''
        df_metrics_seg['extra_03'] = ''
        df_metrics_seg['extra_04'] = ''
        df_metrics_seg['extra_05'] = ''

        cols = ['cod_mes', 'tip_metrica', 'variable', 'estadistico', 'flg_segmento', 'condicion',
                'valor', 'fec_carga', 'extra_01', 'extra_02', 'extra_03', 'extra_04', 'extra_05']

        df_metrics.append(df_metrics_seg[cols])

    df_metrics = pd.concat(df_metrics, ignore_index=True)

    return df_metrics
