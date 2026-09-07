-- f07 RD por r_label_reest x periodo (PRE <=202412 vs ventana FEN >=202504) — DiD-ish
WITH j AS (
  SELECT c.codmes, c.target_12m, r.r_label_reest,
    CASE WHEN c.codmes <= '202412' THEN 'PRE' WHEN c.codmes >= '202504' THEN 'FEN26' ELSE 'MID' END AS periodo
  FROM disc_model_owner.ds_adm_pp_cdpp_cal c
  JOIN disc_model_owner.mca_bd_reniec_xy_r_reest r ON c.key_value = r.key_value
  WHERE c.flg_ibk = 1 AND c.flg_clean = 1 AND c.sub_producto IN ('PP_CD','PP_FACIL')
    AND c.codmes BETWEEN '202301' AND '202507' AND c.target_12m IS NOT NULL
)
SELECT periodo, r_label_reest, count(*) AS n, round(avg(target_12m),4) AS rd12
FROM j GROUP BY periodo, r_label_reest ORDER BY periodo, r_label_reest
