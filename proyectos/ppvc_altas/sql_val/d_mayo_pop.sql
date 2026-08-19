-- =====================================================================================
-- d_mayo_pop | Diagnostico poblacion MAYO. READ-ONLY.
--   scr_vc_orig_bank_calrcc_2_cal NO trae subproducto: veo meses, volumen y PD.
--   Objetivo: saber si es solo altas, que meses cubre, y confirmar que trae 202605.
-- =====================================================================================
SELECT cast(p_codmes AS varchar)                 AS mes,
       count(*)                                  AS n,
       count(DISTINCT key_value)                 AS n_cli,
       round(100*avg(probabilidad), 2)           AS pdraw,
       round(100*avg(prob_modelo_cal_ppfacil),2) AS pit_pf
FROM d_perm_aws.scr_vc_orig_bank_calrcc_2_cal
GROUP BY cast(p_codmes AS varchar)
ORDER BY 1
