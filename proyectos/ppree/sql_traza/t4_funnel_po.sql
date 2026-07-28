-- t4  funnel del paso universo -> perimetro, filtro por filtro y aislado
-- devuelve 1 fila por paso; sin key_value ni identificadores
SELECT 1 AS orden, 'po_universo_pp' AS paso, COUNT(*) AS n, COUNT(DISTINCT codmes_mrm) AS n_meses
FROM disc_model_owner.ds_stk_ree_pp_10_po
UNION ALL
SELECT 2, 'marca_total_todos_subproductos', COUNT(*), COUNT(DISTINCT codmes_desembolso)
FROM d_perm_aws.t_mrm_mongest_altas_pp_marcas_maa_tmp
UNION ALL
SELECT 3, 'marca_subproducto_reenganche', COUNT(*), COUNT(DISTINCT codmes_desembolso)
FROM d_perm_aws.t_mrm_mongest_altas_pp_marcas_maa_tmp
WHERE subproducto = '1.REENGANCHE'
UNION ALL
SELECT 4, 'marca_ree_sin_match_en_puente_cif', COUNT(*), COUNT(DISTINCT a.codmes_desembolso)
FROM d_perm_aws.t_mrm_mongest_altas_pp_marcas_maa_tmp a
LEFT JOIN e_perm_aws.t_mst_ctaibk_rsk b
  ON CAST(a.cif_key AS VARCHAR) = CAST(b.cod_cuc AS VARCHAR)
WHERE a.subproducto = '1.REENGANCHE' AND b.cod_cuc IS NULL
UNION ALL
SELECT 5, 'marca_ree_con_cif_len_distinto_64', COUNT(*), COUNT(DISTINCT a.codmes_desembolso)
FROM d_perm_aws.t_mrm_mongest_altas_pp_marcas_maa_tmp a
INNER JOIN e_perm_aws.t_mst_ctaibk_rsk b
  ON CAST(a.cif_key AS VARCHAR) = CAST(b.cod_cuc AS VARCHAR)
WHERE a.subproducto = '1.REENGANCHE' AND LENGTH(b.key_value) <> 64
UNION ALL
SELECT 6, 'marca_ree_grano_id_codmes', COUNT(*), COUNT(DISTINCT a.codmes_desembolso)
FROM (
  SELECT DISTINCT b.key_value AS id_value, a.codmes_desembolso
  FROM d_perm_aws.t_mrm_mongest_altas_pp_marcas_maa_tmp a
  INNER JOIN e_perm_aws.t_mst_ctaibk_rsk b
    ON CAST(a.cif_key AS VARCHAR) = CAST(b.cod_cuc AS VARCHAR)
  WHERE a.subproducto = '1.REENGANCHE' AND LENGTH(b.key_value) = 64
) a
UNION ALL
SELECT 7, 'marca_ree_sin_fila_en_po', COUNT(*), COUNT(DISTINCT m.codmes_desembolso)
FROM (
  SELECT DISTINCT b.key_value AS id_value, a.codmes_desembolso
  FROM d_perm_aws.t_mrm_mongest_altas_pp_marcas_maa_tmp a
  INNER JOIN e_perm_aws.t_mst_ctaibk_rsk b
    ON CAST(a.cif_key AS VARCHAR) = CAST(b.cod_cuc AS VARCHAR)
  WHERE a.subproducto = '1.REENGANCHE' AND LENGTH(b.key_value) = 64
) m
LEFT JOIN disc_model_owner.ds_stk_ree_pp_10_po p
  ON m.id_value = p.id_value AND m.codmes_desembolso = p.codmes_mrm
WHERE p.id_value IS NULL
ORDER BY 1
