-- h01 perfil REAL de altas PP para el artifact (agregado, sin PII): banda PD x R x tipo x pacifico, con n, PD prom y RD real
WITH j AS (
  SELECT c.pd_raw, c.tipo_ingreso, r.r_label_reest,
    CASE WHEN r.r_nivel_reest>=1 THEN 1 ELSE 0 END AS pac,
    width_bucket(c.pd_raw, 0.0, 0.40, 20) AS pd_band,
    c.target_12m
  FROM disc_model_owner.ds_adm_pp_cdpp_cal c
  JOIN disc_model_owner.mca_bd_reniec_xy_r_reest r ON c.key_value=r.key_value
  WHERE c.flg_ibk=1 AND c.flg_clean=1 AND c.sub_producto IN ('PP_CD','PP_FACIL')
    AND c.codmes BETWEEN '202301' AND '202507'
)
SELECT pd_band, r_label_reest, tipo_ingreso, pac,
  count(*) AS n,
  round(avg(pd_raw),4) AS pd_prom,
  round(avg(CAST(target_12m AS double)),4) AS rd12
FROM j
GROUP BY pd_band, r_label_reest, tipo_ingreso, pac
ORDER BY pd_band, r_label_reest, tipo_ingreso
