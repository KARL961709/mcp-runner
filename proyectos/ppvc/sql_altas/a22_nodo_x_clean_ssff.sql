-- ============================================================================
-- a22. Cruce nodo x flg_clean para SS.FF (flg_ibk=0, PP_FACIL, 202311+).
--      Responde: el N3-masivo es artefacto del scope-out (99)? Si los N3 son
--      casi todos flg_clean=99 y el clean (flg_clean=1) reparte N1/N2/N3, entonces
--      la sobre-penalizacion N3 vive en el fuera-de-alcance, no en lo que se extrapola.
-- ============================================================================
SELECT
    nodo,
    flg_clean,
    COUNT(*) AS n
FROM disc_model_owner.altas_adm_pp_cdpp_cal_ttc
WHERE flg_ibk = 0 AND sub_producto = 'PP_FACIL' AND codmes >= '202311'
GROUP BY nodo, flg_clean
ORDER BY nodo, flg_clean
