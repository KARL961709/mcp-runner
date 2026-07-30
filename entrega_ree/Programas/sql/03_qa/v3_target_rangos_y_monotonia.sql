-- ============================================================================
-- V3. G2 + G10 + monotonia del target. Todo falla_* debe dar 0.
--     La familia es acumulada: target_Nm <= target_(N+1)m siempre.
--     Inmaduro => NULL, jamas 0. Maduro => jamas NULL.
--     falla_mora_no_marcada atrapa un offset o una columna equivocada.
-- ============================================================================
SELECT
  codmes_mrm,
  COUNT(*)                                                                            AS n,
  SUM(CASE WHEN target_12m_60 NOT IN (0,1) THEN 1 ELSE 0 END)                         AS falla_rango,
  SUM(CASE WHEN falla_madurez_12 = 1 AND target_12m_60 IS NOT NULL THEN 1 ELSE 0 END) AS falla_inmaduro_no_null,
  SUM(CASE WHEN falla_madurez_12 = 0 AND target_12m_60 IS NULL THEN 1 ELSE 0 END)     AS falla_maduro_null,
  SUM(CASE WHEN target_01m_60 > target_03m_60 THEN 1 ELSE 0 END)                      AS falla_mono_01_03,
  SUM(CASE WHEN target_03m_60 > target_06m_60 THEN 1 ELSE 0 END)                      AS falla_mono_03_06,
  SUM(CASE WHEN target_06m_60 > target_09m_60 THEN 1 ELSE 0 END)                      AS falla_mono_06_09,
  SUM(CASE WHEN target_09m_60 > target_12m_60 THEN 1 ELSE 0 END)                      AS falla_mono_09_12,
  SUM(CASE WHEN target_12m_30 < target_12m_60 THEN 1 ELSE 0 END)                      AS falla_umbral_30_lt_60,
  SUM(CASE WHEN max_dm_12 > 60 AND target_12m_60 = 0 THEN 1 ELSE 0 END)               AS falla_mora_no_marcada,
  ROUND(AVG(CAST(target_12m_60 AS DOUBLE)), 4)                                        AS rd12
FROM disc_model_owner.ds_stk_ree_pp_35_target
GROUP BY 1
ORDER BY 1
