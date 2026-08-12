-- 31_base_calib.sql | materializa una sola vez el cruce del molde vigente con la pd cruda de Vision Cliente, para no repetir el join contra 26M filas por mes en cada lectura. Una fila por alta y entidad, sin key_value ni tip_doc. NO filtra por flg_est: conserva las dos prelaciones y el flag para reconstruir cualquier variante sin volver a construir, porque prelacion_12m ordena por el target y mete look-ahead en la seleccion. Lleva las cuatro definiciones de target: la publicada, la corregida por evento, la de banda 30-60 y la que combina ambas
CREATE TABLE disc_model_owner.ds_tcnobank_calib_v1
WITH (
    format              = 'PARQUET',
    parquet_compression = 'SNAPPY',
    external_location   = '<S3_DATOS>/tcnobank_v1/'
) AS
SELECT f.p_codmes,
       f.codmes_scr,
       CAST(substr(f.p_codmes, 1, 4) AS INTEGER)                                  AS anio,
       f.nombre_instit_financiera                                                 AS entidad,
       CASE WHEN f.p_codmes <= '202508' THEN 1 ELSE 0 END                         AS flg_maduro,
       f.flg_est,
       f.flg_per,
       f.prelacion_00m,
       f.prelacion_12m,
       f.dsc_flg_malo_06m,
       f.dsc_flg_malo_09m,
       f.dsc_flg_malo_12m,
       f.max_dm_06m,
       f.max_dm_12m,
       CASE WHEN f.nro_dm_m12 IS NULL THEN 0 ELSE 1 END                           AS obs_m12,
       coalesce(f.flg_cstg_12m, 0)                                                AS flg_cstg_12m,
       coalesce(f.flg_jdcl_12m, 0)                                                AS flg_jdcl_12m,
       coalesce(f.flg_rfnc_12m, 0)                                                AS flg_rfnc_12m,
       coalesce(f.flg_rstr_12m, 0)                                                AS flg_rstr_12m,
       TRY_CAST(f.score AS DOUBLE)                                                AS scr_vigente,
       TRY_CAST(s.puntuacion AS DOUBLE)                                           AS scr_nuevo,
       TRY_CAST(s.prob_model AS DOUBLE)                                           AS pd_raw,
       TRY_CAST(s.prob_modelo_cal AS DOUBLE)                                      AS pd_cal_pub,
       TRY_CAST(s.puntuacion_cal AS DOUBLE)                                       AS scr_nuevo_cal,
       s.grupo_calibracion,
       CASE WHEN f.dsc_flg_malo_12m = 'MALO'  THEN 1
            WHEN f.dsc_flg_malo_12m = 'BUENO' THEN 0 END                          AS target_12m,
       CASE WHEN f.dsc_flg_malo_12m = 'MALO' THEN 1
            WHEN f.dsc_flg_malo_12m IN ('UNCASHED', 'INSUFICIENTE', 'INDETERMINADO')
                 AND (coalesce(f.flg_cstg_12m, 0) = 1 OR coalesce(f.flg_jdcl_12m, 0) = 1
                   OR coalesce(f.flg_rfnc_12m, 0) = 1 OR coalesce(f.flg_rstr_12m, 0) = 1) THEN 1
            WHEN f.dsc_flg_malo_12m = 'BUENO' THEN 0 END                          AS target_12m_corr,
       CASE WHEN f.dsc_flg_malo_12m = 'MALO'  THEN 1
            WHEN f.dsc_flg_malo_12m = 'BUENO' THEN 0
            WHEN f.dsc_flg_malo_12m = 'INDETERMINADO' AND f.max_dm_12m < 30 THEN 0 END AS target_12m_b30,
       CASE WHEN f.dsc_flg_malo_12m = 'MALO' THEN 1
            WHEN f.dsc_flg_malo_12m IN ('UNCASHED', 'INSUFICIENTE', 'INDETERMINADO')
                 AND (coalesce(f.flg_cstg_12m, 0) = 1 OR coalesce(f.flg_jdcl_12m, 0) = 1
                   OR coalesce(f.flg_rfnc_12m, 0) = 1 OR coalesce(f.flg_rstr_12m, 0) = 1) THEN 1
            WHEN f.dsc_flg_malo_12m = 'BUENO' THEN 0
            WHEN f.dsc_flg_malo_12m = 'INDETERMINADO' AND f.max_dm_12m < 30 THEN 0 END AS target_12m_full
FROM e_perm_aws.ds_flg_admtcnobk1_rsk f
LEFT JOIN e_perm_aws.scr_vcnbank_rsk s
       ON s.cod_tip_doc = f.tip_doc
      AND s.key_value = f.id_value
      AND s.p_codmes = f.codmes_scr
      AND s.p_codmes BETWEEN '202303' AND '202512'
WHERE f.p_codmes BETWEEN '202305' AND '202602'
  AND f.dsc_flg_malo_12m IN ('BUENO', 'MALO', 'UNCASHED', 'INSUFICIENTE', 'INDETERMINADO',
                             'SWAPS P12M', 'REPRO P12M')
