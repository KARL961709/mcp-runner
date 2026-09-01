-- ============================================================================
-- q30. Monotonicidad: PD PIT media por decil de pd_raw (debe subir con el decil).
-- ============================================================================
SELECT sub_producto, dec,
  COUNT(*) AS n,
  ROUND(MIN(pd_raw), 4) AS pdraw_min,
  ROUND(MAX(pd_raw), 4) AS pdraw_max,
  ROUND(AVG(pd_pit), 4) AS pd_pit_media,
  ROUND(AVG(COALESCE(puntuacion_modelo_ppfacil, puntuacion_modelo_ppcd)), 0) AS punt_media
FROM (
  SELECT sub_producto, pd_raw, pd_pit, puntuacion_modelo_ppfacil, puntuacion_modelo_ppcd,
         NTILE(10) OVER (PARTITION BY sub_producto ORDER BY pd_raw) AS dec
  FROM disc_model_owner.scr_ppvc_cal
)
GROUP BY sub_producto, dec
ORDER BY sub_producto, dec
