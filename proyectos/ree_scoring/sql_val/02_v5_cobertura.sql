-- 02. COBERTURA DE LA v5 POR MES
--   define el rango scoreable: sin pd_raw no hay PD calibrada.
--   pd fuera de (0,1) rompe la BetaCal, que toma ln(p) y ln(1-p).
SELECT CAST(codmes AS VARCHAR)                                                    AS codmes,
       COUNT(*)                                                                   AS n,
       SUM(CASE WHEN pd_comppp_reen_itc IS NOT NULL THEN 1 ELSE 0 END)            AS n_pd,
       SUM(CASE WHEN CAST(pd_comppp_reen_itc AS DOUBLE) <= 0
                  OR CAST(pd_comppp_reen_itc AS DOUBLE) >= 1
                THEN 1 ELSE 0 END)                                                AS viol_pd_rango,
       AVG(CAST(pd_comppp_reen_itc AS DOUBLE))                                    AS pd_prom,
       MIN(CAST(pd_comppp_reen_itc AS DOUBLE))                                    AS pd_min,
       MAX(CAST(pd_comppp_reen_itc AS DOUBLE))                                    AS pd_max
  FROM disc_riesgos.t_b39918_scr_stockpp_itc_reprocesov5
 GROUP BY 1
 ORDER BY 1
