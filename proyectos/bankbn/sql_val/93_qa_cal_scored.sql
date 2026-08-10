-- 93_qa_cal_scored.sql | reconcilia ds_adm_bpe_bankbn_cal_202607 contra su fuente y contra los valores medidos en local. Todo veredicto distinto de OK bloquea el uso de la tabla
WITH n AS (
    SELECT count(1)                                                            AS filas,
           count(DISTINCT CAST(codmes AS VARCHAR))                             AS meses,
           sum(CASE WHEN prob_modelo_cal IS NULL AND pd_raw IS NOT NULL THEN 1 ELSE 0 END) AS pd_null_con_raw,
           sum(CASE WHEN CAST(codmes AS VARCHAR) = '202206' AND pd_raw IS NOT NULL THEN 1 ELSE 0 END) AS raw_202206,
           sum(CASE WHEN puntuacion_modelo < 0 OR puntuacion_modelo > 1000 THEN 1 ELSE 0 END) AS punt_fuera,
           sum(CASE WHEN prob_modelo_cal IS NOT NULL
                     AND puntuacion_modelo <> CAST(round((1.0 - prob_modelo_cal) * 1000) AS INTEGER)
                    THEN 1 ELSE 0 END)                                         AS punt_mal,
           sum(CASE WHEN prob_modelo_cal <= 0 OR prob_modelo_cal >= 1 THEN 1 ELSE 0 END) AS pit_fuera,
           sum(CASE WHEN pd_cal <= 0 OR pd_cal >= 1 THEN 1 ELSE 0 END)         AS cal_fuera,
           sum(CASE WHEN rho_i < 0.001 OR rho_i > 0.999 THEN 1 ELSE 0 END)     AS rho_fuera,
           avg(CASE WHEN entidad = 'IBK' AND flg_calib = 1 THEN prob_modelo_cal END) AS med_aju,
           avg(CASE WHEN entidad = 'IBK' AND flg_calib = 0 AND flg_clean_calib IN (0,1) THEN prob_modelo_cal END) AS med_fwd,
           sum(CASE WHEN flg_clean_calib = 1  AND flg_clean = 0 THEN 1 ELSE 0 END) AS viol_uno,
           sum(CASE WHEN flg_clean_calib = 0  AND flg_clean = 1 THEN 1 ELSE 0 END) AS viol_cero,
           sum(CASE WHEN flg_clean = 1 THEN 1 ELSE 0 END)                      AS clean_uno,
           sum(CASE WHEN flg_clean = 0 THEN 1 ELSE 0 END)                      AS clean_cero,
           sum(CASE WHEN flg_clean_calib = 99 THEN 1 ELSE 0 END)               AS b99,
           sum(CASE WHEN flg_clean_calib = 99 AND flg_clean = 1 THEN 1 ELSE 0 END) AS b99_uno
    FROM disc_model_owner.ds_adm_bpe_bankbn_cal_202607
),
f AS (
    SELECT count(1) AS filas FROM disc_model_owner.ds_adm_bpe_bankbn_cal
)
SELECT orden,
       chequeo,
       round(valor, 4)                                            AS valor,
       referencia,
       CASE WHEN ok = 1 THEN 'OK' ELSE '** REVISAR **' END        AS veredicto
FROM (
    SELECT 1 AS orden, 'filas nueva = filas fuente' AS chequeo,
           CAST(n.filas AS DOUBLE) AS valor, CAST(f.filas AS VARCHAR) AS referencia,
           CASE WHEN n.filas = f.filas THEN 1 ELSE 0 END AS ok
    FROM n, f
    UNION ALL
    SELECT 2, 'sin PD calibrada teniendo pd_raw', CAST(n.pd_null_con_raw AS DOUBLE),
           CAST(n.raw_202206 AS VARCHAR) || ' (los de 202206, sin fhat)',
           CASE WHEN n.pd_null_con_raw = n.raw_202206 THEN 1 ELSE 0 END
    FROM n
    UNION ALL
    SELECT 3, 'puntuacion fuera de [0, 1000]', CAST(n.punt_fuera AS DOUBLE), '0',
           CASE WHEN n.punt_fuera = 0 THEN 1 ELSE 0 END FROM n
    UNION ALL
    SELECT 4, 'puntuacion <> round((1-pd_pit)*1000)', CAST(n.punt_mal AS DOUBLE), '0',
           CASE WHEN n.punt_mal = 0 THEN 1 ELSE 0 END FROM n
    UNION ALL
    SELECT 5, 'prob_modelo_cal fuera de (0, 1)', CAST(n.pit_fuera AS DOUBLE), '0',
           CASE WHEN n.pit_fuera = 0 THEN 1 ELSE 0 END FROM n
    UNION ALL
    SELECT 6, 'pd_cal fuera de (0, 1)', CAST(n.cal_fuera AS DOUBLE), '0',
           CASE WHEN n.cal_fuera = 0 THEN 1 ELSE 0 END FROM n
    UNION ALL
    SELECT 7, 'rho_i fuera de [0.001, 0.999]', CAST(n.rho_fuera AS DOUBLE), '0',
           CASE WHEN n.rho_fuera = 0 THEN 1 ELSE 0 END FROM n
    UNION ALL
    SELECT 8, 'IBK calib=1: media prob_modelo_cal %', 100.0 * n.med_aju, '9.3647 (medido en local)',
           CASE WHEN abs(100.0 * n.med_aju - 9.3647) < 0.05 THEN 1 ELSE 0 END FROM n
    UNION ALL
    SELECT 9, 'IBK calib=0: media prob_modelo_cal %', 100.0 * n.med_fwd, '6.1347 (medido en local, solo clean_calib 0/1)',
           CASE WHEN abs(100.0 * n.med_fwd - 6.1347) < 0.05 THEN 1 ELSE 0 END FROM n
    UNION ALL
    SELECT 10, 'clean_calib=1 debe dar flg_clean=1', CAST(n.viol_uno AS DOUBLE), '0',
           CASE WHEN n.viol_uno = 0 THEN 1 ELSE 0 END FROM n
    UNION ALL
    SELECT 11, 'clean_calib=0 debe dar flg_clean=0', CAST(n.viol_cero AS DOUBLE), '0',
           CASE WHEN n.viol_cero = 0 THEN 1 ELSE 0 END FROM n
    UNION ALL
    SELECT 12, 'flg_clean = 1', CAST(n.clean_uno AS DOUBLE), 'informativo', 1 FROM n
    UNION ALL
    SELECT 13, 'flg_clean = 0', CAST(n.clean_cero AS DOUBLE), 'informativo', 1 FROM n
    UNION ALL
    SELECT 14, 'del bucket 99, cuantos pasan a flg_clean=1', CAST(n.b99_uno AS DOUBLE),
           CAST(n.b99 AS VARCHAR) || ' es el 99 total', 1 FROM n
    UNION ALL
    SELECT 15, 'meses distintos', CAST(n.meses AS DOUBLE), '101 (201802-202606)',
           CASE WHEN n.meses = 101 THEN 1 ELSE 0 END FROM n
) q
ORDER BY orden
