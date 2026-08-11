-- 12_qa_insumo.sql | verifica que el insumo exportado sea consistente con la tabla de origen antes de moverlo
SELECT chequeo, valor, referencia
FROM (
    SELECT 1 AS ord, 'A  filas insumo' AS chequeo, CAST(count(*) AS VARCHAR) AS valor,
           CAST((SELECT count(*) FROM disc_model_owner.ds_adm_bpe_bankbn_cal_202607 WHERE pd_raw IS NOT NULL) AS VARCHAR) AS referencia
    FROM disc_model_owner.ds_adm_bpe_insumo_calib_v4
    UNION ALL
    SELECT 2, 'B  poblaciones distintas', CAST(count(DISTINCT pob) AS VARCHAR), '3 esperadas'
    FROM disc_model_owner.ds_adm_bpe_insumo_calib_v4
    UNION ALL
    SELECT 3, 'C  rango de codmes',
           CAST(min(codmes) AS VARCHAR) || ' a ' || CAST(max(codmes) AS VARCHAR),
           CAST(count(DISTINCT codmes) AS VARCHAR) || ' meses'
    FROM disc_model_owner.ds_adm_bpe_insumo_calib_v4
    UNION ALL
    SELECT 4, 'D  rango de trimestre',
           CAST(min(trimestre) AS VARCHAR) || ' a ' || CAST(max(trimestre) AS VARCHAR),
           CAST(count(DISTINCT trimestre) AS VARCHAR) || ' trimestres'
    FROM disc_model_owner.ds_adm_bpe_insumo_calib_v4
    UNION ALL
    SELECT 5, 'E  nulos en pd_raw o fhat',
           CAST(sum(CASE WHEN pd_raw IS NULL OR fhat IS NULL THEN 1 ELSE 0 END) AS VARCHAR), '0 esperado'
    FROM disc_model_owner.ds_adm_bpe_insumo_calib_v4
    UNION ALL
    SELECT 6, 'F  flg_calib=1 fuera de IBK y TOP4',
           CAST(sum(CASE WHEN flg_calib = 1 AND pob = 'SSFF' THEN 1 ELSE 0 END) AS VARCHAR), '0 esperado'
    FROM disc_model_owner.ds_adm_bpe_insumo_calib_v4
    UNION ALL
    SELECT 7, 'G  evaluables a 12m',
           CAST(sum(CASE WHEN target_12m IS NULL THEN 0 ELSE 1 END) AS VARCHAR),
           CAST(count(*) AS VARCHAR) || ' filas totales'
    FROM disc_model_owner.ds_adm_bpe_insumo_calib_v4
    UNION ALL
    SELECT 8, 'H  fhat distintos por trimestre',
           CAST(count(DISTINCT CAST(trimestre AS VARCHAR) || '|' || CAST(fhat AS VARCHAR)) AS VARCHAR),
           CAST(count(DISTINCT trimestre) AS VARCHAR) || ' esperados si fhat es trimestral'
    FROM disc_model_owner.ds_adm_bpe_insumo_calib_v4
    UNION ALL
    SELECT 9, 'I  pd_pit_vig reproducible',
           CAST(round(100.0 * avg(pd_pit_vig), 4) AS VARCHAR),
           CAST(round(100.0 * avg(pd_raw), 4) AS VARCHAR) || ' de pd_raw media'
    FROM disc_model_owner.ds_adm_bpe_insumo_calib_v4
) t
ORDER BY ord
