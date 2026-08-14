-- 04. CONTRASTE DE LA PD CRUDA v4 CONTRA v5, SOBRE LA INTERSECCION
--   decide si los coeficientes calibrados sobre v4 transfieren a v5.
--   corr ~ 1 y max_dif ~ 0 = misma cosecha, transfieren.
--   Precedente H106 (v2 contra v4): corr 0.9096, max_dif 0.473, hubo que reestimar.
SELECT COUNT(*)                                                                   AS n_comun,
       CORR(a.pd, b.pd)                                                           AS corr_pd,
       MAX(ABS(a.pd - b.pd))                                                      AS max_dif,
       AVG(ABS(a.pd - b.pd))                                                      AS dif_abs_prom,
       AVG(a.pd)                                                                  AS pd_v4_prom,
       AVG(b.pd)                                                                  AS pd_v5_prom,
       SUM(CASE WHEN ABS(a.pd - b.pd) < 1e-9 THEN 1 ELSE 0 END)                   AS n_identicas
  FROM (SELECT CAST(key_value AS VARCHAR)          AS kv,
               CAST(codmes AS VARCHAR)             AS cm,
               CAST(pd_comppp_reen_itc AS DOUBLE)  AS pd
          FROM disc_riesgos.t_b39918_scr_stockpp_itc_reen_reprocesov4
         WHERE pd_comppp_reen_itc IS NOT NULL) a
  JOIN (SELECT CAST(key_value AS VARCHAR)          AS kv,
               CAST(codmes AS VARCHAR)             AS cm,
               CAST(pd_comppp_reen_itc AS DOUBLE)  AS pd
          FROM disc_riesgos.t_b39918_scr_stockpp_itc_reprocesov5
         WHERE pd_comppp_reen_itc IS NOT NULL) b
    ON b.kv = a.kv AND b.cm = a.cm
