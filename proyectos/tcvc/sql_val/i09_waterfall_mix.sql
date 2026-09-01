-- i09. H1 composicion del clean: mix de dsc_flg_malo_12m (UNCASHED/INSUF/INDET forward vs BUENO/MALO vs dirty) en IBK.
SELECT dsc_flg_malo_12m, COUNT(*) AS n,
  SUM(CASE WHEN pd_raw IS NOT NULL THEN 1 ELSE 0 END) AS n_pdraw,
  SUM(CASE WHEN flg_clean = 1 THEN 1 ELSE 0 END) AS n_clean
FROM disc_model_owner.enr_admtcbk_2_v2
WHERE cod_instit_financiera = '00002'
GROUP BY dsc_flg_malo_12m
ORDER BY n DESC