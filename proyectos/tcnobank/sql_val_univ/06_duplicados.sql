-- 06. DUPLICADOS POR MES
--   con INSERT INTO, correr un tramo dos veces duplica sus filas. La 01 lo
--   descarta por conteo, pero un conteo igual con una llave repetida y otra
--   perdida daria lo mismo. Aca se compara contra la cardinalidad de la llave.
--   approx_distinct tiene ~2 por ciento de error: sirve para detectar
--   duplicacion masiva, que es la que produce un tramo repetido, no una fila
SELECT p_codmes                                                                   AS codmes,
       COUNT(*)                                                                   AS n_filas,
       approx_distinct(tip_doc || '|' || id_value)                                AS n_llaves_aprox,
       100.0 * (COUNT(*) - approx_distinct(tip_doc || '|' || id_value))
             / COUNT(*)                                                           AS pct_exceso
  FROM disc_model_owner.scr_univ_vcnbank_tc_cal
 GROUP BY p_codmes
 ORDER BY 1
