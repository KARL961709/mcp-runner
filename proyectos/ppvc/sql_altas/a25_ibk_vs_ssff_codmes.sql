-- ============================================================================
-- a25. IBK vs SS.FF PD vs RD por codmes (202311+, clean maduro, PP_FACIL).
--      Responde: el drift reciente (PD sobre-predice en 2025) es de la extrapolacion
--      a SS.FF, o efecto de libro reciente que TAMBIEN pega en IBK?
--      Si IBK tambien sube el calce en 2025 -> libro reciente (no la extrapolacion).
-- ============================================================================
SELECT
    flg_ibk,
    codmes,
    COUNT(*) AS n,
    avg(CAST(target_12m AS double)) AS rd,
    avg(prob_modelo_cal_ppfacil) AS pd_cal,
    avg(prob_modelo_cal_ppfacil) / avg(CAST(target_12m AS double)) AS calce
FROM disc_model_owner.altas_adm_pp_cdpp_cal_ttc
WHERE sub_producto = 'PP_FACIL' AND flg_clean = 1 AND target_12m IS NOT NULL AND codmes >= '202311'
GROUP BY flg_ibk, codmes
ORDER BY codmes, flg_ibk
