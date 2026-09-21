-- ============================================================================
-- a17. Parte el diff cal (nueva vs desplegada) por flg_ibk: IBK (1) vs SS.FF (0).
--      El nodo es constructo interno IBK -> los no-IBK caen a N3 por ausencia.
--      Si el diff esta solo en flg_ibk=0, la PD desplegada de IBK esta ok.
--      n_nodo_blank_desp/new muestran donde el nodo estaba vacio de cada lado.
-- ============================================================================
SELECT
    t.flg_ibk,
    COUNT(*) AS n,
    SUM(CASE WHEN d.nodo IS NULL OR d.nodo = '' THEN 1 ELSE 0 END) AS n_nodo_blank_desp,
    SUM(CASE WHEN t.nodo IS NULL OR t.nodo = '' THEN 1 ELSE 0 END) AS n_nodo_blank_new,
    SUM(CASE WHEN t.nodo IS DISTINCT FROM d.nodo THEN 1 ELSE 0 END) AS n_dif_nodo,
    SUM(CASE WHEN t.prob_modelo_cal_ppfacil IS NULL AND d.prob_modelo_cal_ppfacil IS NULL THEN 0
             WHEN t.prob_modelo_cal_ppfacil IS NULL OR d.prob_modelo_cal_ppfacil IS NULL THEN 1
             WHEN abs(t.prob_modelo_cal_ppfacil - d.prob_modelo_cal_ppfacil) > 1e-12 THEN 1 ELSE 0 END) AS n_dif_facil,
    SUM(CASE WHEN t.prob_modelo_cal_ppcd IS NULL AND d.prob_modelo_cal_ppcd IS NULL THEN 0
             WHEN t.prob_modelo_cal_ppcd IS NULL OR d.prob_modelo_cal_ppcd IS NULL THEN 1
             WHEN abs(t.prob_modelo_cal_ppcd - d.prob_modelo_cal_ppcd) > 1e-12 THEN 1 ELSE 0 END) AS n_dif_cd
FROM disc_model_owner.altas_adm_pp_cdpp_cal_ttc t
JOIN disc_model_owner.altas_adm_pp_cdpp_cal d
  ON t.tip_doc = d.tip_doc AND t.key_value = d.key_value AND t.codmes = d.codmes
GROUP BY t.flg_ibk
ORDER BY t.flg_ibk
