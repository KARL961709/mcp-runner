-- d_grupos_ppcd_2609. Cambio de composicion G1-GR de PP CD en 202609: score ACTUAL (dirty clasif-only) vs CORREGIDO (dirty riesgo-puro).
--   Mismo set de newly-dirty que Facil (mismo flg_dirty_pp): castigo/refin/reest/judicial. Re-scoreo con calibrador ISOTONICO de CD + overlay 0.0722597767 + ft 0.1002652693 + sqrt(1-rho) 0.9832598843 + lambda 1.
--   Cortes iguales a Facil: G1>=993 G2>=972 G3>=959 G4>=921 G5>=884 G6>=850 GR>=0.
WITH coef_iso_pc(x_lo, x_hi, y_lo, y_hi) AS (VALUES
    (CAST(0.0000000000 AS double),CAST(0.0049012722 AS double),CAST(0.0000000000 AS double),CAST(0.0000000000 AS double)),
    (CAST(0.0049012722 AS double),CAST(0.0191014837 AS double),CAST(0.0000000000 AS double),CAST(0.0000000000 AS double)),
    (CAST(0.0191014837 AS double),CAST(0.0191031024 AS double),CAST(0.0000000000 AS double),CAST(0.0020876827 AS double)),
    (CAST(0.0191031024 AS double),CAST(0.0259118378 AS double),CAST(0.0020876827 AS double),CAST(0.0020876827 AS double)),
    (CAST(0.0259118378 AS double),CAST(0.0259232763 AS double),CAST(0.0020876827 AS double),CAST(0.0056818182 AS double)),
    (CAST(0.0259232763 AS double),CAST(0.0280636102 AS double),CAST(0.0056818182 AS double),CAST(0.0056818182 AS double)),
    (CAST(0.0280636102 AS double),CAST(0.0280724056 AS double),CAST(0.0056818182 AS double),CAST(0.0140127389 AS double)),
    (CAST(0.0280724056 AS double),CAST(0.0362343565 AS double),CAST(0.0140127389 AS double),CAST(0.0140127389 AS double)),
    (CAST(0.0362343565 AS double),CAST(0.0362353250 AS double),CAST(0.0140127389 AS double),CAST(0.0142857143 AS double)),
    (CAST(0.0362353250 AS double),CAST(0.0370077863 AS double),CAST(0.0142857143 AS double),CAST(0.0142857143 AS double)),
    (CAST(0.0370077863 AS double),CAST(0.0370172597 AS double),CAST(0.0142857143 AS double),CAST(0.0161290323 AS double)),
    (CAST(0.0370172597 AS double),CAST(0.0377028733 AS double),CAST(0.0161290323 AS double),CAST(0.0161290323 AS double)),
    (CAST(0.0377028733 AS double),CAST(0.0377206430 AS double),CAST(0.0161290323 AS double),CAST(0.0239361702 AS double)),
    (CAST(0.0377206430 AS double),CAST(0.0591382273 AS double),CAST(0.0239361702 AS double),CAST(0.0239361702 AS double)),
    (CAST(0.0591382273 AS double),CAST(0.0591516942 AS double),CAST(0.0239361702 AS double),CAST(0.0305569246 AS double)),
    (CAST(0.0591516942 AS double),CAST(0.0890215412 AS double),CAST(0.0305569246 AS double),CAST(0.0305569246 AS double)),
    (CAST(0.0890215412 AS double),CAST(0.0890233517 AS double),CAST(0.0305569246 AS double),CAST(0.0438950555 AS double)),
    (CAST(0.0890233517 AS double),CAST(0.1521715373 AS double),CAST(0.0438950555 AS double),CAST(0.0438950555 AS double)),
    (CAST(0.1521715373 AS double),CAST(0.1521926373 AS double),CAST(0.0438950555 AS double),CAST(0.0481927711 AS double)),
    (CAST(0.1521926373 AS double),CAST(0.1572412252 AS double),CAST(0.0481927711 AS double),CAST(0.0481927711 AS double)),
    (CAST(0.1572412252 AS double),CAST(0.1572542340 AS double),CAST(0.0481927711 AS double),CAST(0.0784313725 AS double)),
    (CAST(0.1572542340 AS double),CAST(0.1813758165 AS double),CAST(0.0784313725 AS double),CAST(0.0784313725 AS double)),
    (CAST(0.1813758165 AS double),CAST(0.1815660596 AS double),CAST(0.0784313725 AS double),CAST(0.0807017544 AS double)),
    (CAST(0.1815660596 AS double),CAST(0.2365446240 AS double),CAST(0.0807017544 AS double),CAST(0.0807017544 AS double)),
    (CAST(0.2365446240 AS double),CAST(0.2376354784 AS double),CAST(0.0807017544 AS double),CAST(0.1027397260 AS double)),
    (CAST(0.2376354784 AS double),CAST(0.4905883968 AS double),CAST(0.1027397260 AS double),CAST(0.1027397260 AS double)),
    (CAST(0.4905883968 AS double),CAST(0.4960871339 AS double),CAST(0.1027397260 AS double),CAST(0.5000000000 AS double)),
    (CAST(0.4960871339 AS double),CAST(0.7061473727 AS double),CAST(0.5000000000 AS double),CAST(0.5000000000 AS double)),
    (CAST(0.7061473727 AS double),CAST(1.0000001000 AS double),CAST(0.5000000000 AS double),CAST(0.5000000000 AS double))
),
base AS (
  SELECT CAST(s.puntuacion_modelo_cal_ppcd AS integer) AS punt_curr,
    CASE WHEN s.flg_dirty_pp = 0 AND (d.a_cast = 1 OR d.a_ref = 1 OR d.a_ree_pp = 1 OR d.a_jud = 1) THEN 1 ELSE 0 END AS newly,
    greatest(least(CAST(s.pd_raw AS double), 1 - 1e-6), 1e-6) AS p
  FROM disc_model_owner.scr_vcadmbnk_final_rsk_cal_2609 s
  JOIN disc_model_owner.scr_vcadmbnk_final_rsk_cal_2609_dirty d
    ON d.codmes = s.codmes AND d.key_value = s.key_value AND d.cod_tip_doc = s.cod_tip_doc
),
cal AS (
  SELECT b.punt_curr, b.newly,
    ic.y_lo + (ic.y_hi - ic.y_lo) * (b.p - ic.x_lo) / (ic.x_hi - ic.x_lo) AS pcal
  FROM base b
  LEFT JOIN coef_iso_pc ic ON b.p >= ic.x_lo AND b.p < ic.x_hi
),
sc AS (
  SELECT punt_curr,
    CASE WHEN newly = 1 THEN CAST(round(1000.0 * (1 - normal_cdf(0, 1,
      (inverse_normal_cdf(0, 1, greatest(least(pcal, 1 - 1e-6), 1e-6)) + 0.0722597767 + 1.0 * 0.1002652693) / 0.9832598843))) AS integer)
    ELSE punt_curr END AS punt_corr
  FROM cal
),
g AS (
  SELECT
    CASE WHEN punt_curr >= 993 THEN 'G1' WHEN punt_curr >= 972 THEN 'G2' WHEN punt_curr >= 959 THEN 'G3' WHEN punt_curr >= 921 THEN 'G4' WHEN punt_curr >= 884 THEN 'G5' WHEN punt_curr >= 850 THEN 'G6' ELSE 'GR' END AS g_curr,
    CASE WHEN punt_corr >= 993 THEN 'G1' WHEN punt_corr >= 972 THEN 'G2' WHEN punt_corr >= 959 THEN 'G3' WHEN punt_corr >= 921 THEN 'G4' WHEN punt_corr >= 884 THEN 'G5' WHEN punt_corr >= 850 THEN 'G6' ELSE 'GR' END AS g_corr
  FROM sc
)
SELECT COALESCE(a.grupo, b.grupo) AS grupo,
  COALESCE(a.n, 0) AS n_actual,
  COALESCE(b.n, 0) AS n_corregido,
  COALESCE(b.n, 0) - COALESCE(a.n, 0) AS delta
FROM (SELECT g_curr AS grupo, COUNT(*) AS n FROM g GROUP BY g_curr) a
FULL OUTER JOIN (SELECT g_corr AS grupo, COUNT(*) AS n FROM g GROUP BY g_corr) b ON a.grupo = b.grupo
ORDER BY grupo
