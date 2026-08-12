-- ============================================================================
-- 92. CONTROLES DEL TARGET AGRUPADO - SIN MADUROS Y DEGENERADO
-- ============================================================================
SELECT h.horizonte,
       count(h.t)                                                                      AS n_maduros,
       sum(h.t)                                                                        AS n_malos,
       round(100.0 * avg(CAST(h.t AS DOUBLE)), 4)                                      AS bad_rate,
       CAST(CASE WHEN count(h.t) = 0 THEN 1 ELSE 0 END AS INTEGER)                     AS falla_sin_maduros,
       CAST(CASE WHEN avg(CAST(h.t AS DOUBLE)) IN (0.0, 1.0) THEN 1 ELSE 0 END AS INTEGER) AS falla_degenerado
FROM disc_model_owner.ds_adm_vcnbank_tc_cal c
CROSS JOIN UNNEST(
    ARRAY['01m','02m','03m','04m','05m','06m','07m','08m','09m','10m','11m','12m'],
    ARRAY[c.target_01m, c.target_02m, c.target_03m, c.target_04m, c.target_05m, c.target_06m,
          c.target_07m, c.target_08m, c.target_09m, c.target_10m, c.target_11m, c.target_12m])
     AS h (horizonte, t)
WHERE c.flg_calib = 1 AND c.flg_clean = 1
GROUP BY h.horizonte
ORDER BY h.horizonte
