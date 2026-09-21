-- ============================================================================
-- a14. Ejemplos reales (25 filas) donde la cal Facil difiere > 1pp entre NUEVA y DESPLEGADA.
--      Muestra pd_raw / tipo / nodo / flg_clean de ambos lados para ver la causa.
--      SIN key_value. Ordena por codmes desc para ver los meses recientes primero.
-- ============================================================================
SELECT
    t.codmes,
    t.pd_raw AS pdraw_new, d.pd_raw AS pdraw_desp,
    t.tipo_ingreso AS tipo_new, d.tipo_ingreso AS tipo_desp,
    t.nodo AS nodo_new, d.nodo AS nodo_desp,
    t.flg_clean AS clean_new, d.flg_clean AS clean_desp,
    t.prob_modelo_cal_ppfacil AS facil_new, d.prob_modelo_cal_ppfacil AS facil_desp
FROM disc_model_owner.altas_adm_pp_cdpp_cal_ttc t
JOIN disc_model_owner.altas_adm_pp_cdpp_cal d
  ON t.tip_doc = d.tip_doc AND t.key_value = d.key_value AND t.codmes = d.codmes
WHERE t.prob_modelo_cal_ppfacil IS NOT NULL AND d.prob_modelo_cal_ppfacil IS NOT NULL
  AND abs(t.prob_modelo_cal_ppfacil - d.prob_modelo_cal_ppfacil) > 0.01
ORDER BY t.codmes DESC
LIMIT 25
