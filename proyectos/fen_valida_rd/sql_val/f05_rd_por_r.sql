-- f05 RD real (target_12m) por score directo r_label_reest — monotonia y recorte duro R4/R5
WITH j AS (
  SELECT c.pd_raw, c.target_12m, r.r_label_reest
  FROM disc_model_owner.ds_adm_pp_cdpp_cal c
  JOIN disc_model_owner.mca_bd_reniec_xy_r_reest r ON c.key_value = r.key_value
  WHERE c.flg_ibk = 1 AND c.flg_clean = 1 AND c.sub_producto IN ('PP_CD','PP_FACIL')
    AND c.codmes BETWEEN '202301' AND '202507' AND c.target_12m IS NOT NULL
)
SELECT r_label_reest, count(*) AS n, round(avg(pd_raw),4) AS pd_raw_prom, round(avg(target_12m),4) AS rd12
FROM j GROUP BY r_label_reest ORDER BY r_label_reest
