-- c02 control de ejecucion + MISSING por mes. pd_raw/cal deben ser 0 missing. nodos y tipo_ingreso muestran cuanto cae a fallback. dirty/clean.
SELECT codmes,
       COUNT(*) AS n,
       SUM(CASE WHEN prob_modelo IS NULL THEN 1 ELSE 0 END) AS miss_pdraw,
       SUM(CASE WHEN prob_modelo_cal_ppfacil IS NULL THEN 1 ELSE 0 END) AS miss_cal_facil,
       SUM(CASE WHEN prob_modelo_cal_ppcd IS NULL THEN 1 ELSE 0 END) AS miss_cal_ppcd,
       SUM(CASE WHEN nodo_ppfacil IS NULL OR nodo_ppfacil NOT IN ('NODO 1','NODO 2','NODO 3') THEN 1 ELSE 0 END) AS miss_nodo_facil,
       SUM(CASE WHEN nodo_ppcd IS NULL OR nodo_ppcd NOT IN ('NODO 1','NODO 2','NODO 3') THEN 1 ELSE 0 END) AS miss_nodo_ppcd,
       SUM(CASE WHEN tipo_ingreso IS NULL THEN 1 ELSE 0 END) AS miss_tipoing_fallback,
       SUM(flg_dirty_pp) AS n_dirty,
       SUM(flg_clean) AS n_clean
FROM disc_model_owner.scr_admvc_pp_cal_202401_202608
GROUP BY codmes
ORDER BY codmes
