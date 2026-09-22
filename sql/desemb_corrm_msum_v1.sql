-- desemb_corrm_msum_v1.sql | RESUMEN migracion V1: total, cuantos se quedan en el mismo grupo, cuantos migran, % que migra. Agregado.
SELECT COUNT(*) AS n_total,
  SUM(CASE WHEN o.grupo_cal=n.grupo_cal THEN 1 ELSE 0 END) AS n_mismo_grupo,
  SUM(CASE WHEN o.grupo_cal<>n.grupo_cal THEN 1 ELSE 0 END) AS n_migra,
  ROUND(100.0*SUM(CASE WHEN o.grupo_cal<>n.grupo_cal THEN 1 ELSE 0 END)/COUNT(*),2) AS pct_migra
FROM disc_model_owner.b46029_desemb_maestra_rec_202609 o
JOIN disc_model_owner.b46029_desemb_maestra_corrv1_202609 n ON o.cod_mes=n.cod_mes AND o.cod_tip_doc=n.cod_tip_doc AND o.key_value=n.key_value
WHERE o.flg_cruce=1 AND n.flg_cruce=1
