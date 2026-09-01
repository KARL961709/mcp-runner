-- ============================================================================
-- q30. Monotonicidad: ambas prob medias por decil de pd_raw (deben subir juntas).
-- ============================================================================
SELECT dec,
  COUNT(*) AS n,
  ROUND(MIN(pd_raw), 4) AS pdraw_min,
  ROUND(MAX(pd_raw), 4) AS pdraw_max,
  ROUND(AVG(prob_modelo_ppfacil), 4) AS prob_facil,
  ROUND(AVG(prob_modelo_ppcd), 4) AS prob_cd
FROM (
  SELECT pd_raw, prob_modelo_ppfacil, prob_modelo_ppcd,
         NTILE(10) OVER (ORDER BY pd_raw) AS dec
  FROM disc_model_owner.scr_ppvc_cal
)
GROUP BY dec
ORDER BY dec
