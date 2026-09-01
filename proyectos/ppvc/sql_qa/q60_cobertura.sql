-- ============================================================================
-- q60. Cobertura de ancla (nivel t/n/p/d) por producto y split flg_ibk (B2).
--      nivel_=p en no-IBK = extrapolacion del modelo IBK (visibilidad requerida).
-- ============================================================================
SELECT flg_ibk, nivel_facil, nivel_cd, COUNT(*) AS n
FROM disc_model_owner.scr_ppvc_cal
GROUP BY flg_ibk, nivel_facil, nivel_cd
ORDER BY flg_ibk, nivel_facil, nivel_cd
