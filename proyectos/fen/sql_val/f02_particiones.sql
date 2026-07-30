-- f02 LLAVES DE PARTICION de las fuentes que toca el proyecto
SELECT table_schema, table_name, column_name, ordinal_position
FROM information_schema.columns
WHERE extra_info = 'partition key'
  AND ((table_schema = 'e_perm_aws'
        AND table_name IN ('ds_flg_comportc_rsk','ds_flg_compppibk_rsk','scr_comportc_rsk',
                           't_mst_reniec_rsk','t_agg_censo_enrich_rsk','scr_geopositions',
                           'scr_vcclibnk_rsk'))
    OR (table_schema = 'd_perm_aws'
        AND table_name IN ('scr_vcadmbnk_hist_rsk','t_mst_zonas_afectadas_tmp')))
ORDER BY 1, 2, 4
