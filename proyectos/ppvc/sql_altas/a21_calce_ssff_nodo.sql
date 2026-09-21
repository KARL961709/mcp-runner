-- ============================================================================
-- a21. Valida la extrapolacion a SS.FF: calce PD vs RD por flg_ibk x nodo.
--      PP_FACIL, clean (flg_clean=1) maduro (target_12m not null).
--      Si en SS.FF pd_cal >> rd (sobre todo N3) -> N3-por-ausencia sobre-penaliza
--      (ceguera, no riesgo) y hay que corregir el trato del no-visto.
--      Si pd_cal ~ rd -> la extrapolacion con el nodo de ds_adm es correcta.
-- ============================================================================
SELECT
    flg_ibk,
    nodo,
    COUNT(*) AS n,
    SUM(CAST(target_12m AS double)) AS n_bad,
    avg(CAST(target_12m AS double)) AS rd,
    avg(prob_modelo_cal_ppfacil) AS pd_cal,
    avg(prob_modelo_ttc_ppfacil) AS pd_ttc,
    avg(prob_modelo_cal_ppfacil) / avg(CAST(target_12m AS double)) AS calce
FROM disc_model_owner.altas_adm_pp_cdpp_cal_ttc
WHERE sub_producto = 'PP_FACIL' AND flg_clean = 1 AND target_12m IS NOT NULL
GROUP BY flg_ibk, nodo
ORDER BY flg_ibk, nodo
