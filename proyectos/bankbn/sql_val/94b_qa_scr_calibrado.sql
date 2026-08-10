-- 94b_qa_scr_calibrado.sql | QA de scr_admbankbpe_calibrado_202607. Los chequeos 11 y 12 son el cruce contra la tabla de altas: mismo cliente, mismo mes, misma cadena y mismos coeficientes deben dar la MISMA PD al bit
WITH n AS (
    SELECT count(1)                                                                AS filas,
           count(DISTINCT p_codmes)                                                AS periodos,
           min(p_codmes)                                                           AS pm_min,
           max(p_codmes)                                                           AS pm_max,
           sum(CASE WHEN prob_modelo_cal IS NULL THEN 1 ELSE 0 END)                AS sin_pd,
           sum(CASE WHEN fhat IS NULL THEN 1 ELSE 0 END)                           AS sin_fhat,
           sum(CASE WHEN prob_modelo_cal <= 0 OR prob_modelo_cal >= 1 THEN 1 ELSE 0 END) AS pit_fuera,
           sum(CASE WHEN pd_cal <= 0 OR pd_cal >= 1 THEN 1 ELSE 0 END)             AS cal_fuera,
           sum(CASE WHEN rho_i < 0.001 OR rho_i > 0.999 THEN 1 ELSE 0 END)         AS rho_fuera,
           sum(CASE WHEN puntuacion_modelo < 0 OR puntuacion_modelo > 1000 THEN 1 ELSE 0 END) AS punt_fuera,
           sum(CASE WHEN prob_modelo_cal IS NOT NULL
                     AND puntuacion_modelo <> CAST(round((1.0 - prob_modelo_cal) * 1000) AS INTEGER)
                    THEN 1 ELSE 0 END)                                             AS punt_mal,
           sum(CASE WHEN personeria = 'PJJ' THEN 1 ELSE 0 END)                     AS n_pjj,
           avg(prob_modelo)                                                        AS med_raw,
           avg(prob_modelo_cal)                                                    AS med_cal
    FROM disc_model_owner.scr_admbankbpe_calibrado_202607
),
f AS (
    SELECT count(1) AS filas
    FROM (SELECT DISTINCT CAST(tip_doc AS VARCHAR) AS td, key_value, p_codmes
          FROM e_perm_aws.scr_admbankbpe_rsk
          WHERE p_codmes BETWEEN '202206' AND '202607'
            AND probabilidad IS NOT NULL) z
),
x AS (
    SELECT count(1)                                                                AS pares,
           sum(CASE WHEN abs(a.prob_modelo_cal - s.prob_modelo_cal) > 1e-9 THEN 1 ELSE 0 END) AS pd_distinta,
           sum(CASE WHEN a.personeria_cal <> s.personeria THEN 1 ELSE 0 END)       AS per_distinta,
           max(abs(a.prob_modelo_cal - s.prob_modelo_cal))                         AS maxdif
    FROM (SELECT CAST(tip_doc AS VARCHAR) AS td, CAST(key_value AS VARCHAR) AS kv,
                 CAST(codmes AS INT) AS cm, prob_modelo_cal,
                 CASE WHEN COALESCE(flg_ppjj,0) = 1 THEN 'PJJ' ELSE 'PNN' END AS personeria_cal
          FROM disc_model_owner.ds_adm_bpe_bankbn_cal_202607
          WHERE prob_modelo_cal IS NOT NULL) a
    JOIN (SELECT CAST(tip_doc AS VARCHAR) AS td, CAST(key_value AS VARCHAR) AS kv,
                 codmes_alta AS cm, prob_modelo_cal, personeria
          FROM disc_model_owner.scr_admbankbpe_calibrado_202607
          WHERE prob_modelo_cal IS NOT NULL) s
      ON a.td = s.td AND a.kv = s.kv AND a.cm = s.cm
)
SELECT orden, chequeo, round(valor, 6) AS valor, referencia,
       CASE WHEN ok = 1 THEN 'OK' ELSE '** REVISAR **' END AS veredicto
FROM (
    SELECT 1 AS orden, 'filas = claves distintas en la fuente' AS chequeo,
           CAST(n.filas AS DOUBLE) AS valor, CAST(f.filas AS VARCHAR) AS referencia,
           CASE WHEN n.filas = f.filas THEN 1 ELSE 0 END AS ok FROM n, f
    UNION ALL SELECT 2, 'periodos distintos', CAST(n.periodos AS DOUBLE), '50 (202206-202607)',
           CASE WHEN n.periodos = 50 THEN 1 ELSE 0 END FROM n
    UNION ALL SELECT 3, 'primer p_codmes', CAST(CAST(n.pm_min AS INT) AS DOUBLE), '202206',
           CASE WHEN n.pm_min = '202206' THEN 1 ELSE 0 END FROM n
    UNION ALL SELECT 4, 'ultimo p_codmes', CAST(CAST(n.pm_max AS INT) AS DOUBLE), '202607',
           CASE WHEN n.pm_max = '202607' THEN 1 ELSE 0 END FROM n
    UNION ALL SELECT 5, 'sin PD calibrada', CAST(n.sin_pd AS DOUBLE), '0',
           CASE WHEN n.sin_pd = 0 THEN 1 ELSE 0 END FROM n
    UNION ALL SELECT 6, 'sin fhat', CAST(n.sin_fhat AS DOUBLE), '0',
           CASE WHEN n.sin_fhat = 0 THEN 1 ELSE 0 END FROM n
    UNION ALL SELECT 7, 'prob_modelo_cal fuera de (0,1)', CAST(n.pit_fuera AS DOUBLE), '0',
           CASE WHEN n.pit_fuera = 0 THEN 1 ELSE 0 END FROM n
    UNION ALL SELECT 8, 'pd_cal o rho_i fuera de rango', CAST(n.cal_fuera + n.rho_fuera AS DOUBLE), '0',
           CASE WHEN n.cal_fuera + n.rho_fuera = 0 THEN 1 ELSE 0 END FROM n
    UNION ALL SELECT 9, 'puntuacion fuera de [0,1000]', CAST(n.punt_fuera AS DOUBLE), '0',
           CASE WHEN n.punt_fuera = 0 THEN 1 ELSE 0 END FROM n
    UNION ALL SELECT 10, 'puntuacion <> round((1-pd)*1000)', CAST(n.punt_mal AS DOUBLE), '0',
           CASE WHEN n.punt_mal = 0 THEN 1 ELSE 0 END FROM n
    UNION ALL SELECT 11, 'cruce altas: PD distinta', CAST(x.pd_distinta AS DOUBLE),
           CAST(x.pares AS VARCHAR) || ' pares cruzados',
           CASE WHEN x.pd_distinta = 0 THEN 1 ELSE 0 END FROM x
    UNION ALL SELECT 12, 'cruce altas: personeria distinta', CAST(x.per_distinta AS DOUBLE), '0',
           CASE WHEN x.per_distinta = 0 THEN 1 ELSE 0 END FROM x
    UNION ALL SELECT 13, 'cruce altas: max dif de PD', x.maxdif, '< 1e-9',
           CASE WHEN x.maxdif < 1e-9 THEN 1 ELSE 0 END FROM x
    UNION ALL SELECT 14, 'PJJ sobre el total %', 100.0 * n.n_pjj / n.filas, 'informativo', 1 FROM n
    UNION ALL SELECT 15, 'prob_modelo media %', 100.0 * n.med_raw, 'informativo', 1 FROM n
    UNION ALL SELECT 16, 'prob_modelo_cal media %', 100.0 * n.med_cal, 'informativo', 1 FROM n
) q
ORDER BY orden
