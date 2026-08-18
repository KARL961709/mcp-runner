-- 03. CONTRATO FISICO DE LAS LLAVES, en un solo mes
--   antes de cualquier join hay que medir el formato de LAS DOS llaves. Aca se
--   mide el lado de scr_vcnbank_rsk: que valores toma cod_tip_doc y de que
--   largo viene key_value. Si el largo o el padding no coinciden con id_value
--   del ds_, el join no falla: devuelve vacio en silencio
SELECT cod_tip_doc,
       length(CAST(key_value AS VARCHAR))                                       AS largo_key,
       COUNT(*)                                                                 AS n_filas,
       SUM(CASE WHEN CAST(key_value AS VARCHAR) <> trim(CAST(key_value AS VARCHAR))
                THEN 1 ELSE 0 END)                                              AS n_con_espacios,
       SUM(CASE WHEN substr(CAST(key_value AS VARCHAR), 1, 1) = '0'
                THEN 1 ELSE 0 END)                                              AS n_con_cero_inicial,
       SUM(CASE WHEN TRY_CAST(prob_model AS DOUBLE) IS NULL THEN 1 ELSE 0 END)  AS n_pd_no_castea,
       SUM(CASE WHEN TRY_CAST(puntuacion AS INTEGER) IS NULL THEN 1 ELSE 0 END) AS n_punt_no_castea
  FROM e_perm_aws.scr_vcnbank_rsk
 WHERE p_codmes = '202605'
 GROUP BY cod_tip_doc, length(CAST(key_value AS VARCHAR))
 ORDER BY 3 DESC
