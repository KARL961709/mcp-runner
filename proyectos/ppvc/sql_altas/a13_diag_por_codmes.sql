-- ============================================================================
-- a13. Diagnostico: por que difiere la cal. Descompone el diff por codmes y por campo.
--      Compara la NUEVA (lee ds_adm hoy) vs la DESPLEGADA (snapshot). Solo agregados.
--      Si n_dif_pdraw grande -> la fuente ds_adm cambio (pd_raw re-scoreado).
--      Si n_dif_pdraw ~0 pero n_dif_facil grande -> cambiaron coefs/ft, no la fuente.
-- ============================================================================
SELECT
    t.codmes,
    COUNT(*) AS n,
    SUM(CASE WHEN t.pd_raw IS NULL AND d.pd_raw IS NULL THEN 0
             WHEN t.pd_raw IS NULL OR d.pd_raw IS NULL THEN 1
             WHEN abs(t.pd_raw - d.pd_raw) > 1e-9 THEN 1 ELSE 0 END) AS n_dif_pdraw,
    SUM(CASE WHEN t.tipo_ingreso IS DISTINCT FROM d.tipo_ingreso THEN 1 ELSE 0 END) AS n_dif_tipo,
    SUM(CASE WHEN t.nodo IS DISTINCT FROM d.nodo THEN 1 ELSE 0 END) AS n_dif_nodo,
    SUM(CASE WHEN t.flg_clean IS DISTINCT FROM d.flg_clean THEN 1 ELSE 0 END) AS n_dif_clean,
    SUM(CASE WHEN t.prob_modelo_cal_ppfacil IS NULL AND d.prob_modelo_cal_ppfacil IS NULL THEN 0
             WHEN t.prob_modelo_cal_ppfacil IS NULL OR d.prob_modelo_cal_ppfacil IS NULL THEN 1
             WHEN abs(t.prob_modelo_cal_ppfacil - d.prob_modelo_cal_ppfacil) > 1e-12 THEN 1 ELSE 0 END) AS n_dif_facil
FROM disc_model_owner.altas_adm_pp_cdpp_cal_ttc t
JOIN disc_model_owner.altas_adm_pp_cdpp_cal d
  ON t.tip_doc = d.tip_doc AND t.key_value = d.key_value AND t.codmes = d.codmes
GROUP BY t.codmes
ORDER BY t.codmes
