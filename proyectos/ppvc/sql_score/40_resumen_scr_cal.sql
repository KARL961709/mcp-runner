-- ============================================================================
-- v10. Resumen post-build: n, medias de prob por producto, rango puntuacion, nulls.
-- ============================================================================
SELECT flg_clean,
       COUNT(*) AS n,
       ROUND(AVG(prob_modelo_ppfacil), 4) AS pd_facil,
       ROUND(AVG(prob_modelo_ppcd), 4) AS pd_cd,
       SUM(CASE WHEN prob_modelo_ppfacil IS NULL OR prob_modelo_ppcd IS NULL THEN 1 ELSE 0 END) AS nulls
FROM disc_model_owner.scr_ppvc_cal
GROUP BY flg_clean
ORDER BY flg_clean
