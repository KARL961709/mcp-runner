-- 01. COLUMNAS DE LAS TABLAS QUE NECESITA EL SCORER
--   v4 = la fuente sobre la que se calibro. v5 = la que se quiere scorear.
--   v2 = la que scoreaba el scorer anterior. t_mst_bcrp_rsk = la macro gobernada.
--   Si una tabla no aparece en el resultado, no existe con ese nombre.
SELECT table_schema,
       table_name,
       COUNT(*)                                                                   AS n_columnas,
       array_join(array_agg(column_name || ' ' || data_type
                            ORDER BY ordinal_position), ' | ')                    AS columnas
  FROM information_schema.columns
 WHERE (table_schema = 'disc_riesgos'
        AND table_name IN ('t_b39918_scr_stockpp_itc_reen_reprocesov4',
                           't_b39918_scr_stockpp_itc_reprocesov5',
                           't_b39918_scr_stockpp_itc_reprocesov2_desencriptado'))
    OR (table_schema = 'e_perm_aws' AND table_name = 't_mst_bcrp_rsk')
 GROUP BY 1, 2
 ORDER BY 1, 2
