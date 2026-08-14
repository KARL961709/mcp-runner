-- 11. LA SALIDA VIGENTE DEL SCORER Y SU ESQUEMA
--   el scoring ya corre por mes con el patron scr_stk_ree_pp_cal_YYYYMM. El mes
--   nuevo tiene que respetar ese contrato, no inventar uno: mismas columnas,
--   mismos tipos, mismo orden.
--   Devuelve una fila por tabla existente, asi que tambien dice cuantos meses
--   hay materializados y cual es el ultimo.
SELECT table_schema,
       table_name,
       COUNT(*)                                                                   AS n_columnas,
       array_join(array_agg(column_name || ' ' || data_type
                            ORDER BY ordinal_position), ' | ')                    AS columnas
  FROM information_schema.columns
 WHERE table_schema IN ('d_perm_aws', 'disc_model_owner', 'e_perm_aws')
   AND (table_name LIKE 'scr_stk_ree_pp_cal%'
     OR table_name LIKE 'scr_comppp_ree%')
 GROUP BY 1, 2
 ORDER BY 1, 2
