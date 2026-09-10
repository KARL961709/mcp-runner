-- d_grupos_pp_2609. Cambio de composicion G1-GR de PP Facil en 202609: score ACTUAL (dirty clasif-only) vs CORREGIDO (dirty riesgo-puro).
--   Corregido = re-scoreo solo de los que pasan clean->dirty por riesgo (castigo/refin/reest/judicial), aplicando overlay 0.0722597767.
--   Calibrador beta y constantes = las mismas del build u02_scored_2609 (M=-0.1460672524, A=1.0405635434, B=2.5746e-11, ft_pp=0.1002652693, sqrt(1-rho)=0.9832598843, lambda=1).
--   Cortes G1>=993 G2>=972 G3>=959 G4>=921 G5>=884 G6>=850 GR>=0.
WITH base AS (
  SELECT CAST(s.puntuacion_modelo_cal_ppfacil AS integer) AS punt_curr,
    CASE WHEN s.flg_dirty_pp = 0 AND (d.a_cast = 1 OR d.a_ref = 1 OR d.a_ree_pp = 1 OR d.a_jud = 1) THEN 1 ELSE 0 END AS newly,
    greatest(least(CAST(s.pd_raw AS double), 1 - 1e-6), 1e-6) AS p
  FROM disc_model_owner.scr_vcadmbnk_final_rsk_cal_2609 s
  JOIN disc_model_owner.scr_vcadmbnk_final_rsk_cal_2609_dirty d
    ON d.codmes = s.codmes AND d.key_value = s.key_value AND d.cod_tip_doc = s.cod_tip_doc
),
sc AS (
  SELECT punt_curr,
    CASE WHEN newly = 1 THEN CAST(round(1000.0 * (1 - normal_cdf(0, 1,
      (inverse_normal_cdf(0, 1, greatest(least(1.0 / (1.0 + exp(-(-0.1460672524 + 1.0405635434 * ln(p) - 2.5746e-11 * ln(1 - p)))), 1 - 1e-6), 1e-6)) + 0.0722597767 + 1.0 * 0.1002652693) / 0.9832598843))) AS integer)
    ELSE punt_curr END AS punt_corr
  FROM base
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
