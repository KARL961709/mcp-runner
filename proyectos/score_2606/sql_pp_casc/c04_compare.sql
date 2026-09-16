-- c04 compara clasif-only (scored_pil) vs cascada (scored_casc_pil): flips clean->dirty y delta PD/puntuacion. 202401. Read-only.
SELECT
  COUNT(*) AS n,
  SUM(s.flg_clean) AS n_clean_clasif,
  SUM(c.flg_clean) AS n_clean_casc,
  SUM(1 - s.flg_clean) AS n_dirty_clasif,
  SUM(1 - c.flg_clean) AS n_dirty_casc,
  SUM(CASE WHEN s.flg_clean = 1 AND c.flg_clean = 0 THEN 1 ELSE 0 END) AS n_flip_clean_to_dirty,
  round(AVG(s.prob_modelo_cal_ppfacil) * 100, 4) AS pd_ppfacil_clasif_pct,
  round(AVG(c.prob_modelo_cal_ppfacil) * 100, 4) AS pd_ppfacil_casc_pct,
  round(AVG(c.prob_modelo_cal_ppfacil - s.prob_modelo_cal_ppfacil) * 100, 4) AS d_pd_ppfacil_pct,
  round(AVG(s.prob_modelo_cal_ppcd) * 100, 4) AS pd_ppcd_clasif_pct,
  round(AVG(c.prob_modelo_cal_ppcd) * 100, 4) AS pd_ppcd_casc_pct,
  round(AVG(c.prob_modelo_cal_ppcd - s.prob_modelo_cal_ppcd) * 100, 4) AS d_pd_ppcd_pct
FROM disc_model_owner.scr_admvc_pp_cal_202401_202606 s
JOIN disc_model_owner.scr_admvc_pp_cal_202401_202606_casc c
  ON c.codmes = s.codmes AND c.key_value = s.key_value AND c.cod_tip_doc = s.cod_tip_doc
