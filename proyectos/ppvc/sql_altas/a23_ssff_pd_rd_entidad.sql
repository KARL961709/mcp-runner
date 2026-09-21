-- ============================================================================
-- a23. SS.FF (otras entidades) PD vs RD por entidad + total (ROLLUP).
--      PP_FACIL, clean (flg_clean=1) maduro. Como queda la extrapolacion por entidad.
--      La fila con cod_instit_financiera NULL = total SS.FF. Solo agregados.
-- ============================================================================
SELECT
    cod_instit_financiera,
    COUNT(*) AS n,
    SUM(CAST(target_12m AS double)) AS n_bad,
    avg(CAST(target_12m AS double)) AS rd,
    avg(prob_modelo_cal_ppfacil) AS pd_cal,
    avg(prob_modelo_ttc_ppfacil) AS pd_ttc,
    avg(prob_modelo_cal_ppfacil) / avg(CAST(target_12m AS double)) AS calce
FROM disc_model_owner.altas_adm_pp_cdpp_cal_ttc
WHERE flg_ibk = 0 AND sub_producto = 'PP_FACIL' AND flg_clean = 1 AND target_12m IS NOT NULL
GROUP BY ROLLUP (cod_instit_financiera)
ORDER BY cod_instit_financiera
