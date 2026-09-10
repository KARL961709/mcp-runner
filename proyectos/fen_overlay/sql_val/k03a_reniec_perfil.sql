-- k03a perfil de mca_bd_reniec_xy_r_reest: cuantas filas / llaves distintas tiene, y de esas cuantas traen ubigeo y R_reest no nulos. Responde si la tabla es el techo real (~19.6M geo-resueltos) o si trae huecos. Read-only, 1 fila. k00b ya probo que NO es bug de llave (ulen=rlen=64, pct_match 70.37)
SELECT
  count(*)                                                     AS n_filas,
  count(distinct key_value)                                   AS n_keys_distintas,
  sum(CASE WHEN ubigeo_inei_nodo IS NOT NULL THEN 1 ELSE 0 END) AS n_con_ubigeo,
  sum(CASE WHEN r_nivel_reest    IS NOT NULL THEN 1 ELSE 0 END) AS n_con_r_reest
FROM disc_model_owner.mca_bd_reniec_xy_r_reest
