-- d_impact_pp_riesgo_2609. Impacto del dirty PP corregido = RIESGO RCC puro (SIN bancarizado, SIN entidad 00004).
--   corr_riesgo      = clasif(actual) + castigo(u24m) + refin(u6m) + reest(u6m) + judicial(u24m).  origen(m-2) va dentro de cada ventana.
--   corr_con_edad    = lo anterior + edad fuera [21,75]   (para que decidas si edad entra o no).
WITH j AS (
  SELECT s.tipo_ingreso, s.nodo_ppfacil, s.flg_dirty_pp AS curr,
    CASE WHEN s.flg_dirty_pp = 1 OR d.a_cast = 1 OR d.a_ref = 1 OR d.a_ree_pp = 1 OR d.a_jud = 1
         THEN 1 ELSE 0 END AS corr_riesgo,
    CASE WHEN s.flg_dirty_pp = 1 OR d.a_cast = 1 OR d.a_ref = 1 OR d.a_ree_pp = 1 OR d.a_jud = 1 OR d.a_edad = 1
         THEN 1 ELSE 0 END AS corr_con_edad,
    s.puntuacion_modelo_cal_ppfacil AS punt
  FROM disc_model_owner.scr_vcadmbnk_final_rsk_cal_2609 s
  JOIN disc_model_owner.scr_vcadmbnk_final_rsk_cal_2609_dirty d
    ON d.codmes = s.codmes AND d.key_value = s.key_value AND d.cod_tip_doc = s.cod_tip_doc
)
SELECT tipo_ingreso, nodo_ppfacil, COUNT(*) AS n,
  ROUND(AVG(CAST(curr AS double)), 4) AS dirty_clasif,
  ROUND(AVG(CAST(corr_riesgo AS double)), 4) AS dirty_riesgo,
  ROUND(AVG(CAST(corr_con_edad AS double)), 4) AS dirty_con_edad,
  SUM(CASE WHEN corr_riesgo = 1 AND curr = 0 THEN 1 ELSE 0 END) AS n_pasa_riesgo,
  SUM(CASE WHEN corr_con_edad = 1 AND corr_riesgo = 0 THEN 1 ELSE 0 END) AS n_extra_edad,
  ROUND(AVG(CAST(punt AS double)), 0) AS punt_prom_grupo
FROM j
GROUP BY GROUPING SETS ((tipo_ingreso, nodo_ppfacil), ())
ORDER BY tipo_ingreso, nodo_ppfacil
