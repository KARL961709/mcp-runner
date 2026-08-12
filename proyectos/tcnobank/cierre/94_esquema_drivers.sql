-- 94_esquema_drivers.sql | esquema de las fuentes que entran como driver y como segmento tras la decision de reusar la calibracion previa: la cascada de ingresos que produce el DEP_VAL, la tabla macro que alimenta los dos arboles, RENIEC y el puente de party_id. Va primero para no adivinar nombres en las siguientes
SELECT table_schema,
       table_name,
       count(*)                                                            AS n_cols,
       array_join(array_agg(column_name ORDER BY ordinal_position), ' | ') AS columnas
FROM information_schema.columns
WHERE table_schema IN ('e_perm_aws', 'd_perm_aws')
  AND table_name IN ('ds_rtd_rskvol_cas_ingr_ir', 't_fact_bpe_vars_macro',
                     't_mst_reniec_rsk', 't_mst_inter_ibk_base_cliente')
GROUP BY table_schema, table_name
ORDER BY table_name, table_schema
