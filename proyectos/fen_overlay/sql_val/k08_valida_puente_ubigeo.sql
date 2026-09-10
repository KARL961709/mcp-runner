-- k08: valida el puente ubigeo RENIEC->INEI con los 9.1M que estan en AMBAS tablas. e_perm base trae cod_ubi_domicilio (RENIEC); r_reest trae ubigeo_reniec + ubigeo_formato_inei. Confirma si cod_ubi_domicilio calza con el RENIEC o ya es INEI, y las longitudes (formato). Con esto se arma el diccionario cod_ubi_domicilio->INEI para los 3.83M sin XY, evitando el trap Piura->Puno. Read-only, 1 fila
SELECT
  count(*)                                                                 AS n,
  sum(CASE WHEN b.cod_ubi_domicilio = r.ubigeo_reniec THEN 1 ELSE 0 END)   AS n_eq_reniec,
  sum(CASE WHEN b.cod_ubi_domicilio = r.ubigeo_formato_inei THEN 1 ELSE 0 END) AS n_eq_inei,
  min(length(b.cod_ubi_domicilio)) AS len_cod_min,
  max(length(b.cod_ubi_domicilio)) AS len_cod_max,
  min(length(r.ubigeo_reniec))     AS len_reniec_min,
  min(length(r.ubigeo_formato_inei)) AS len_inei_min
FROM e_perm_aws.t_mst_reniec_rsk b
JOIN disc_model_owner.mca_bd_reniec_xy_r_reest r ON b.key_value = r.key_value
