-- f06 RD por decil de pd_raw x r_label_reest — el R aporta mas alla del baseline (control por PD)
WITH j AS (
  SELECT c.pd_raw, c.target_12m, r.r_label_reest
  FROM disc_model_owner.ds_adm_pp_cdpp_cal c
  JOIN disc_model_owner.mca_bd_reniec_xy_r_reest r ON c.key_value = r.key_value
  WHERE c.flg_ibk = 1 AND c.flg_clean = 1 AND c.sub_producto IN ('PP_CD','PP_FACIL')
    AND c.codmes BETWEEN '202301' AND '202507' AND c.target_12m IS NOT NULL
),
b AS (SELECT pd_raw, target_12m, r_label_reest, ntile(10) OVER (ORDER BY pd_raw) AS pd_dec FROM j)
SELECT pd_dec, r_label_reest, count(*) AS n, round(avg(target_12m),4) AS rd12
FROM b GROUP BY pd_dec, r_label_reest ORDER BY pd_dec, r_label_reest
