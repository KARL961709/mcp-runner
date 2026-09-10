-- d_impact_pp_2609. Impacto de la correccion del dirty PP por grupo (tipo_ingreso x nodo_ppfacil), sin reconstruir.
--   Compara dirty clasif-only (lo que fue a produccion) vs dirty portable (clasif + castigo/refin/reest/judicial/bancarizado/edad/entidad).
--   Los brazos ya estan como columnas en la tabla _dirty. Nota: a_bank_pp es por presencia (no saldo) -> es cota ALTA del bancarizado.
WITH j AS (
  SELECT s.tipo_ingreso, s.nodo_ppfacil, s.flg_dirty_pp AS curr,
    CASE WHEN s.flg_dirty_pp = 1 OR d.a_cast = 1 OR d.a_ref = 1 OR d.a_ree_pp = 1 OR d.a_jud = 1
              OR d.a_bank_pp = 1 OR d.a_edad = 1 OR d.a_ent4 = 1 THEN 1 ELSE 0 END AS corr,
    s.puntuacion_modelo_cal_ppfacil AS punt
  FROM disc_model_owner.scr_vcadmbnk_final_rsk_cal_2609 s
  JOIN disc_model_owner.scr_vcadmbnk_final_rsk_cal_2609_dirty d
    ON d.codmes = s.codmes AND d.key_value = s.key_value AND d.cod_tip_doc = s.cod_tip_doc
)
SELECT tipo_ingreso, nodo_ppfacil, COUNT(*) AS n,
  ROUND(AVG(CAST(curr AS double)), 4) AS dirty_clasif,
  ROUND(AVG(CAST(corr AS double)), 4) AS dirty_portable,
  SUM(CASE WHEN corr = 1 AND curr = 0 THEN 1 ELSE 0 END) AS n_pasa_a_dirty,
  ROUND(AVG(CASE WHEN corr = 1 AND curr = 0 THEN CAST(punt AS double) END), 0) AS punt_prom_nuevos,
  ROUND(AVG(CAST(punt AS double)), 0) AS punt_prom_grupo
FROM j
GROUP BY GROUPING SETS ((tipo_ingreso, nodo_ppfacil), ())
ORDER BY tipo_ingreso, nodo_ppfacil
