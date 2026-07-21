-- =====================================================================================
-- ORIGEN BPE PD · V2 · BUILD (crea tablas)
--   archivo : CALIB_1_altas.sql
--   origen  : ~\Documents\2026\GDM\Origen_BPE_PD_V2\_src\CALIB_1_altas.sql
--   sha256  : d944c806ed37   (del cuerpo, sin este encabezado)
--   estado  : ROJO
--   nota    : altas desde altas_rep — fuente madre unica
-- =====================================================================================
-- =====================================================================================
-- CALIB_1_altas.sql | ETAPA 1a — la poblacion de altas, DESDE FUENTE MADRE
--
-- ESCRIBE: disc_model_owner.b46029_calib_altas
--
-- FUENTE MADRE UNICA
--   disc_monitorian.t_dan_mrm_admbankbpe_altas_rep   202207-202604
--
-- Es el tramo 'oficial' de q1_altas_src.sql, VERBATIM en sus derivadas. NO incluye el
-- tramo 'rcc_crudo' 201801-202206, que en el original sale de bnbpe_altas_larga
-- (derivada) y necesita ademas d_perm_aws + t_dim_inst_fin_rsk.
--   -> Para la ventana de calibracion 202207-202505 ese tramo NO hace falta.
--   -> Si despues se quiere RD historica pre-2022, es un build aparte.
--
-- SE CONSERVA VERBATIM DEL ORIGINAL
--   personeria    tip_doc='2' -> PJJ, si no PNN           (DRIVER de la calibracion)
--   flg_ibk       cod_instit_financiera = '00002'
--   top4_entidad  IN ('00001','00002','00004','00006')
--   flg_monto     (30000<=max_saldo AND saldo_m0 in [10000,30000)) OR saldo_m0>=30000
--
-- LO QUE NO SE COPIA, Y POR QUE
--   flg_rank1   era constante=1 porque "rank=1 ya viene aplicado upstream". Se conserva
--               `rank` crudo para VERIFICARLO en CALIB_3 en vez de asumirlo.
--   fuente_altas se fija a 'oficial': aqui hay un solo tramo.
--
-- Si ya existe: DROP TABLE disc_model_owner.b46029_calib_altas
-- =====================================================================================
CREATE TABLE disc_model_owner.b46029_calib_altas
WITH (format='PARQUET', parquet_compression='SNAPPY') AS
SELECT
    cast(codmes AS varchar)                           AS codmes,
    tip_doc,
    key_value,
    CASE WHEN tip_doc = '2' THEN 'PJJ' ELSE 'PNN' END AS personeria,
    cod_instit_financiera,
    nombre_instit_financiera,
    CASE WHEN cod_instit_financiera = '00002' THEN 1 ELSE 0 END AS flg_ibk,
    CASE WHEN cod_instit_financiera IN ('00001','00002','00004','00006')
         THEN 'TOP4' ELSE 'OTRO' END                  AS top4_entidad,
    cast(rank AS bigint)                              AS rank,
    cast(saldo_m0  AS double)                         AS saldo_m0,
    cast(max_saldo AS double)                         AS max_saldo,
    CASE WHEN ((30000 <= max_saldo AND (saldo_m0 >= 10000 AND saldo_m0 < 30000))
               OR (saldo_m0 >= 30000))
         THEN 1 ELSE 0 END                            AS flg_monto,
    'oficial'                                         AS fuente_altas,
    cast(p_codmes AS varchar)                         AS p_codmes
FROM disc_monitorian.t_dan_mrm_admbankbpe_altas_rep
WHERE p_codmes BETWEEN '202207' AND '202604'
  AND cast(codmes AS int) BETWEEN 202207 AND 202604
