-- d_pdraw_check. Confirma que pd_raw del universo = probabilidad de la fuente d_perm_aws.scr_vcadmbnk_final_hist_rsk.
--   n_diff=0 (o max_diff ~1e-16 por el round-trip via score) -> pd_raw jalado bien. src_null=0 -> todos matchean la fuente.
SELECT u.codmes, COUNT(*) AS n,
  SUM(CASE WHEN ABS(u.pd_raw - s.probabilidad) > 1e-9 THEN 1 ELSE 0 END) AS n_diff,
  ROUND(MAX(ABS(u.pd_raw - s.probabilidad)), 12) AS max_diff,
  SUM(CASE WHEN s.probabilidad IS NULL THEN 1 ELSE 0 END) AS src_null
FROM disc_model_owner.scr_vcadmbnk_final_hist_rsk_cal_2606_2608 u
LEFT JOIN (
  SELECT CAST(codmes AS varchar) AS codmes, key_value, CAST(cod_tip_doc AS varchar) AS cod_tip_doc, probabilidad,
         ROW_NUMBER() OVER (PARTITION BY codmes, key_value, cod_tip_doc ORDER BY probabilidad DESC) AS rn
  FROM d_perm_aws.scr_vcadmbnk_final_hist_rsk
  WHERE probabilidad IS NOT NULL AND cod_tip_doc = '1'
    AND CAST(codmes AS varchar) BETWEEN '202606' AND '202608'
) s ON s.codmes = u.codmes AND s.key_value = u.key_value AND s.cod_tip_doc = u.cod_tip_doc AND s.rn = 1
GROUP BY u.codmes
ORDER BY u.codmes
