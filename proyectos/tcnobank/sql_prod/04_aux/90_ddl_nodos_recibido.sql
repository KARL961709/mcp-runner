-- ============================================================================
-- 90. TABLA EXTERNA SOBRE EL CSV DE NODOS RECIBIDO
--   Recibidos2/nodos.csv, 18,664 filas, 202410-202504, solo entidad 2. Es el
--   unico insumo que permite validar el nodo contra la fuente original EN SQL,
--   que es el lenguaje en el que corre el despliegue.
--
--   ANTES DE CORRER: subir Data/nodos_recibido.tsv a
--     s3://ibk-discovery-riesgos-us-east-1-339712995012-data/discovery/model_owner/B46029/tcnb/nodos_recibido/
--   Un solo archivo en esa carpeta y nada mas: la tabla externa lee TODO lo que
--   encuentre ahi.
--
--   POR QUE TSV Y NO EL CSV TAL CUAL. El original viene separado por punto y
--   coma y con comillas dobles como caracter de cita. Las dos cosas rompen el
--   G0 del puente, que rechaza cualquier punto y coma y exige comillas dobles
--   pares. Convertirlo a tab evita las dos y no pierde nada: medido, ninguna
--   celda del archivo contiene tabs, saltos de linea ni comillas dobles, y la
--   relectura del tsv es identica al csv original.
--
--   Todas las columnas entran como string a proposito: forzar tipos aca haria
--   fallar la carga entera por una celda. Los cast van en la comparacion.
--
--   OJO CON LAS LLAVES. El csv trae TIP_DOC = 1 y COD_INSTIT_FINANCIERA = 2,
--   mientras que el ds_ usa entidad con ceros a la izquierda. La comparacion
--   filtra por entidad del lado nuestro y no toca el csv.
-- ============================================================================
CREATE EXTERNAL TABLE disc_model_owner.aux_nodos_recibido (
    codmes                    string,
    key_value                 string,
    tip_doc                   string,
    cod_instit_financiera     string,
    tipo_cliente              string,
    tipo_alta                 string,
    grupos_tc_nb              string,
    target60_12_vc            string,
    cns_realizado_m12         string,
    flg_vc_nb_new_v3          string,
    prob_vc_nb_new_v3         string,
    puntaje_vc_nb_new_v3      string,
    niveles_vc_nb_new_v3      string,
    flag_pasivos_afp_f        string,
    flg_cs_v2                 string,
    cant_trx_in_out_tot_u3m   string,
    cant_30_prm_out_tot_u3m   string,
    cant_20_trx_out_tot_u3m   string,
    flg_plinero_u3m           string,
    flg_plin_f1               string,
    flg_plin_f2               string,
    nodo_final                string
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
LOCATION 's3://ibk-discovery-riesgos-us-east-1-339712995012-data/discovery/model_owner/B46029/tcnb/nodos_recibido/'
TBLPROPERTIES ('skip.header.line.count' = '1')
