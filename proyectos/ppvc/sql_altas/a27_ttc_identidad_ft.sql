-- ============================================================================
-- a27. Valida la TTC por identidad: (probit(PIT) - probit(TTC)) * sqrt(1-rho) = ft del mes.
--      IBK clean, PP_FACIL. Si ft_implicito coincide con la senda coef_ft (ej 202606=0.08581,
--      202607=0.08671, 202608=0.09522) -> la TTC es exactamente la PIT sin el termino macro.
--      Rango de ft_implicito ~0 dentro del mes confirma que es un escalar por codmes.
-- ============================================================================
SELECT
    codmes,
    COUNT(*) AS n,
    avg((inverse_normal_cdf(0, 1, prob_modelo_cal_ppfacil) - inverse_normal_cdf(0, 1, prob_modelo_ttc_ppfacil)) * 0.9832598843) AS ft_implicito,
    max((inverse_normal_cdf(0, 1, prob_modelo_cal_ppfacil) - inverse_normal_cdf(0, 1, prob_modelo_ttc_ppfacil)) * 0.9832598843)
      - min((inverse_normal_cdf(0, 1, prob_modelo_cal_ppfacil) - inverse_normal_cdf(0, 1, prob_modelo_ttc_ppfacil)) * 0.9832598843) AS rango_ft
FROM disc_model_owner.altas_adm_pp_cdpp_cal_ttc
WHERE flg_ibk = 1 AND flg_clean = 1 AND sub_producto = 'PP_FACIL'
  AND prob_modelo_cal_ppfacil IS NOT NULL AND prob_modelo_ttc_ppfacil IS NOT NULL
GROUP BY codmes
ORDER BY codmes
