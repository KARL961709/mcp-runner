-- ============================================================================
-- q20. Integridad: nulls de pd_pit, XOR de producto, rangos pd_pit/punt/pd_raw.
--      Todas las columnas de conteo deben dar 0.
-- ============================================================================
SELECT
  COUNT(*) AS n,
  SUM(CASE WHEN pd_pit IS NULL THEN 1 ELSE 0 END) AS pd_pit_null,
  SUM(CASE WHEN pd_pit <= 0 OR pd_pit >= 1 THEN 1 ELSE 0 END) AS pd_pit_fuera_01,
  SUM(CASE WHEN (prob_modelo_ppfacil IS NOT NULL AND prob_modelo_ppcd IS NOT NULL)
              OR (prob_modelo_ppfacil IS NULL AND prob_modelo_ppcd IS NULL)
           THEN 1 ELSE 0 END) AS xor_violado,
  SUM(CASE WHEN COALESCE(puntuacion_modelo_ppfacil, puntuacion_modelo_ppcd) NOT BETWEEN 0 AND 1000 THEN 1 ELSE 0 END) AS punt_fuera_0_1000,
  SUM(CASE WHEN pd_raw <= 0 OR pd_raw >= 1 THEN 1 ELSE 0 END) AS pd_raw_fuera_01,
  SUM(CASE WHEN sub_producto IS NULL OR sub_producto NOT IN ('PP_FACIL', 'PP_CD') THEN 1 ELSE 0 END) AS subprod_raro
FROM disc_model_owner.scr_ppvc_cal
