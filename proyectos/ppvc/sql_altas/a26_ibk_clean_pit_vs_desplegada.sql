-- ============================================================================
-- a26. IBK clean (flg_ibk=1 AND flg_clean=1): PIT cal nueva vs desplegada = 0 diff?
--      + avg PIT vs avg TTC (sanity). Confirma que la PD PIT coincide con la version ya creada.
--      Solo agregados, key_value solo en el ON.
-- ============================================================================
SELECT
    COUNT(*) AS n,
    SUM(CASE WHEN abs(t.prob_modelo_cal_ppfacil - d.prob_modelo_cal_ppfacil) > 1e-12 THEN 1 ELSE 0 END) AS n_dif_pit_facil,
    SUM(CASE WHEN abs(t.prob_modelo_cal_ppcd - d.prob_modelo_cal_ppcd) > 1e-12 THEN 1 ELSE 0 END) AS n_dif_pit_cd,
    max(abs(t.prob_modelo_cal_ppfacil - d.prob_modelo_cal_ppfacil)) AS maxdif_pit_facil,
    max(abs(t.prob_modelo_cal_ppcd - d.prob_modelo_cal_ppcd)) AS maxdif_pit_cd,
    avg(t.prob_modelo_cal_ppfacil) AS avg_pit_facil,
    avg(t.prob_modelo_ttc_ppfacil) AS avg_ttc_facil,
    avg(t.prob_modelo_cal_ppcd) AS avg_pit_cd,
    avg(t.prob_modelo_ttc_ppcd) AS avg_ttc_cd
FROM disc_model_owner.altas_adm_pp_cdpp_cal_ttc t
JOIN disc_model_owner.altas_adm_pp_cdpp_cal d
  ON t.tip_doc = d.tip_doc AND t.key_value = d.key_value AND t.codmes = d.codmes
WHERE t.flg_ibk = 1 AND t.flg_clean = 1 AND t.prob_modelo_cal_ppfacil IS NOT NULL
