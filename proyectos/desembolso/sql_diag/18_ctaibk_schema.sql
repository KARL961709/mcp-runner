-- 18_ctaibk_schema.sql | columnas y tipos de e_perm_aws.t_mst_ctaibk_rsk, el puente cod_cuc <-> key_value para unir el RCD (t_ifrs_rcddeta_rsk trae cod_cuc) con user_desembolso (trae key_value). Confirma los nombres exactos de las columnas antes de escribir el join. Solo metadata. READ-ONLY
SELECT ordinal_position, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'e_perm_aws' AND table_name = 't_mst_ctaibk_rsk'
ORDER BY ordinal_position
