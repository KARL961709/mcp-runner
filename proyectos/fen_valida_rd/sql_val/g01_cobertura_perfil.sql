-- g01 cobertura del join + perfil FEN de la cartera (altas PP IBK clean, codmes>=202101); fila r_label_reest NULL = sin match RENIEC
SELECT r.r_label_reest,
  count(*) AS altas,
  sum(CASE WHEN r.r_nivel_reest>=1 THEN 1 ELSE 0 END) AS pacifico,
  sum(CASE WHEN r.ubigeo_formato_inei IS NOT NULL THEN 1 ELSE 0 END) AS con_ubigeo_inei,
  round(avg(c.pd_raw),4) AS pd_raw_prom
FROM disc_model_owner.ds_adm_pp_cdpp_cal c
LEFT JOIN disc_model_owner.mca_bd_reniec_xy_r_reest r ON c.key_value=r.key_value
WHERE c.flg_ibk=1 AND c.flg_clean=1 AND c.sub_producto IN ('PP_CD','PP_FACIL') AND c.codmes>='202101'
GROUP BY r.r_label_reest ORDER BY r.r_label_reest
