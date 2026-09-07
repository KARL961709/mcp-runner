-- s01. Cobertura 202604-202608 en: score fuente (pd_raw), insumos ds_*_cal y desplegadas altas_*_cal
--      de los 4 modelos. n = filas, n_valor = pd_raw NOT NULL (fuente/ds) o prob_modelo_cal NOT NULL (altas).
--      Dice si hay que reprocesar el ds o solo re-scorear. READ-ONLY.
SELECT fuente, codmes, COUNT(*) AS n, SUM(hasval) AS n_valor
FROM (
  SELECT 'a_score_src' AS fuente, CAST(codmes AS varchar) AS codmes,
         CASE WHEN probabilidad IS NOT NULL THEN 1 ELSE 0 END AS hasval
    FROM d_perm_aws.scr_vcadmbnk_final_hist_rsk
   WHERE CAST(codmes AS varchar) BETWEEN '202604' AND '202608'
  UNION ALL
  SELECT 'tc_ds', CAST(codmes AS varchar), CASE WHEN pd_raw IS NOT NULL THEN 1 ELSE 0 END
    FROM disc_model_owner.ds_adm_tcbank_cal
   WHERE CAST(codmes AS varchar) BETWEEN '202604' AND '202608'
  UNION ALL
  SELECT 'tc_altas', CAST(codmes AS varchar), CASE WHEN prob_modelo_cal IS NOT NULL THEN 1 ELSE 0 END
    FROM disc_model_owner.altas_adm_tcbank_cal
   WHERE CAST(codmes AS varchar) BETWEEN '202604' AND '202608'
  UNION ALL
  SELECT 'pp_ds', CAST(codmes AS varchar), CASE WHEN pd_raw IS NOT NULL THEN 1 ELSE 0 END
    FROM disc_model_owner.ds_adm_pp_cdpp_cal
   WHERE CAST(codmes AS varchar) BETWEEN '202604' AND '202608'
  UNION ALL
  SELECT 'pp_altas', CAST(codmes AS varchar), CASE WHEN prob_modelo_cal_ppfacil IS NOT NULL THEN 1 ELSE 0 END
    FROM disc_model_owner.altas_adm_pp_cdpp_cal
   WHERE CAST(codmes AS varchar) BETWEEN '202604' AND '202608'
  UNION ALL
  SELECT 'ec_ds', CAST(codmes AS varchar), CASE WHEN pd_raw IS NOT NULL THEN 1 ELSE 0 END
    FROM disc_model_owner.ds_ec_cdd_cal
   WHERE CAST(codmes AS varchar) BETWEEN '202604' AND '202608'
  UNION ALL
  SELECT 'ec_altas', CAST(codmes AS varchar), CASE WHEN prob_modelo_cal IS NOT NULL THEN 1 ELSE 0 END
    FROM disc_model_owner.altas_ec_cal
   WHERE CAST(codmes AS varchar) BETWEEN '202604' AND '202608'
) t
GROUP BY fuente, codmes
ORDER BY fuente, codmes
