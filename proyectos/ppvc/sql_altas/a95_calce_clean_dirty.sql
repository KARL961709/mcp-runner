-- a95. Calce PD calibrada vs RD por flg_clean (1=clean, 0=dirty, 99=scope-out) x sub_producto,
--      fit maduro 202311-202507. Dirty (flg_clean=0): el overlay +0.07226 debe subir pd_cal ~ RD dirty.
SELECT flg_clean, sub_producto, flg_ibk, COUNT(*) AS n,
  ROUND(AVG(prob_modelo_cal_ppfacil), 5) AS pd_facil,
  ROUND(AVG(prob_modelo_cal_ppcd), 5) AS pd_cd,
  ROUND(AVG(CAST(target_12m AS double)), 5) AS rd
FROM disc_model_owner.altas_adm_pp_cdpp_cal
WHERE codmes BETWEEN '202311' AND '202507' AND target_12m IS NOT NULL
GROUP BY flg_clean, sub_producto, flg_ibk
ORDER BY flg_clean, sub_producto, flg_ibk