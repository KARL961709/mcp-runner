-- ============================================================================
-- v10. Resumen post-build de scr_ppvc_cal: n, PD media, rango puntuacion, nulls.
-- ============================================================================
SELECT sub_producto,
       COUNT(*) AS n,
       ROUND(AVG(COALESCE(prob_modelo_ppfacil, prob_modelo_ppcd)), 4) AS pd_media,
       MIN(COALESCE(puntuacion_modelo_ppfacil, puntuacion_modelo_ppcd)) AS punt_min,
       MAX(COALESCE(puntuacion_modelo_ppfacil, puntuacion_modelo_ppcd)) AS punt_max,
       SUM(CASE WHEN COALESCE(prob_modelo_ppfacil, prob_modelo_ppcd) IS NULL THEN 1 ELSE 0 END) AS pd_nulls
FROM disc_model_owner.scr_ppvc_cal
GROUP BY sub_producto
ORDER BY sub_producto
