-- ============================================================================
-- a24. SS.FF (otras entidades) PD vs RD por codmes (tendencia).
--      PP_FACIL, clean (flg_clean=1) maduro. Ve si el calce se sostiene en el tiempo.
--      Solo aparecen cohortes maduras (target_12m no nulo). Solo agregados.
-- ============================================================================
SELECT
    codmes,
    COUNT(*) AS n,
    avg(CAST(target_12m AS double)) AS rd,
    avg(prob_modelo_cal_ppfacil) AS pd_cal,
    avg(prob_modelo_ttc_ppfacil) AS pd_ttc,
    avg(prob_modelo_cal_ppfacil) / avg(CAST(target_12m AS double)) AS calce
FROM disc_model_owner.altas_adm_pp_cdpp_cal_ttc
WHERE flg_ibk = 0 AND sub_producto = 'PP_FACIL' AND flg_clean = 1 AND target_12m IS NOT NULL
GROUP BY codmes
ORDER BY codmes
