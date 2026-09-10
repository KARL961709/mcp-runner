-- j05: cobertura geo del libro de altas recientes (202605-207, clean IBK, PP_CD/FACIL). Mide full vs XY-matched (r_reest, lo que hoy muestra el artifact = 17809) vs recuperable por domicilio declarado (e_perm base con cod_ubi_domicilio valido). Mismo patron que la PEA (k00b+k05). Read-only, 1 fila
SELECT
  count(*)                                                                                   AS n_altas_full,
  count(r.key_value)                                                                         AS n_con_xy,
  count(CASE WHEN r.key_value IS NULL THEN b.key_value END)                                  AS n_sin_xy_en_base,
  count(CASE WHEN r.key_value IS NULL AND b.cod_ubi_domicilio IS NOT NULL AND length(b.cod_ubi_domicilio)=6 THEN 1 END) AS n_recup_con_ubigeo
FROM disc_model_owner.altas_adm_pp_cdpp_cal a
LEFT JOIN disc_model_owner.mca_bd_reniec_xy_r_reest r ON a.key_value = r.key_value
LEFT JOIN e_perm_aws.t_mst_reniec_rsk b ON a.key_value = b.key_value
WHERE a.flg_ibk = 1 AND a.flg_clean = 1 AND a.sub_producto IN ('PP_CD','PP_FACIL')
  AND a.codmes BETWEEN '202605' AND '202607'
