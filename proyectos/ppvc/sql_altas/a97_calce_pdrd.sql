-- a97. Calce PD calibrada vs RD (target_12m) - clean maduro 202311-202507 (todas las entidades),
--      por sub_producto. PP_FACIL: prob_modelo_cal_ppfacil vs rd ; PP_CD: prob_modelo_cal_ppcd vs rd.
SELECT sub_producto, COUNT(*) AS n,
  ROUND(AVG(prob_modelo_cal_ppfacil), 5) AS pd_facil,
  ROUND(AVG(prob_modelo_cal_ppcd), 5) AS pd_cd,
  ROUND(AVG(CAST(target_12m AS double)), 5) AS rd
FROM disc_model_owner.altas_adm_pp_cdpp_cal
WHERE flg_clean = 1 AND codmes BETWEEN '202311' AND '202507' AND target_12m IS NOT NULL
GROUP BY sub_producto
ORDER BY sub_producto