-- ============================================================================
-- F5. R8 - FORMATO DE LA LLAVE MEDIDO EN LOS CUATRO LADOS DEL JOIN
-- ============================================================================
SELECT 'flag_prod.id_value' AS lado, COUNT(*) AS n,
       MIN(LENGTH(CAST(id_value AS VARCHAR))) AS len_min,
       MAX(LENGTH(CAST(id_value AS VARCHAR))) AS len_max,
       SUM(CASE WHEN CAST(id_value AS VARCHAR) <> TRIM(CAST(id_value AS VARCHAR)) THEN 1 ELSE 0 END) AS n_con_espacios,
       COUNT(DISTINCT CAST(tip_doc AS VARCHAR)) AS n_dom_tip_doc
FROM e_perm_aws.ds_flg_compppibk_rsk
UNION ALL
SELECT 'puente.key_value', COUNT(*),
       MIN(LENGTH(CAST(key_value AS VARCHAR))), MAX(LENGTH(CAST(key_value AS VARCHAR))),
       SUM(CASE WHEN CAST(key_value AS VARCHAR) <> TRIM(CAST(key_value AS VARCHAR)) THEN 1 ELSE 0 END),
       COUNT(DISTINCT CAST(tip_doc AS VARCHAR))
FROM e_perm_aws.t_mst_ctaibk_rsk
UNION ALL
SELECT 'pd_v4.key_value', COUNT(*),
       MIN(LENGTH(CAST(key_value AS VARCHAR))), MAX(LENGTH(CAST(key_value AS VARCHAR))),
       SUM(CASE WHEN CAST(key_value AS VARCHAR) <> TRIM(CAST(key_value AS VARCHAR)) THEN 1 ELSE 0 END),
       COUNT(DISTINCT CAST(tip_doc AS VARCHAR))
FROM disc_riesgos.t_b39918_scr_stockpp_itc_reen_reprocesov4
UNION ALL
SELECT 'cta_sueldo.key_value', COUNT(*),
       MIN(LENGTH(CAST(key_value AS VARCHAR))), MAX(LENGTH(CAST(key_value AS VARCHAR))),
       SUM(CASE WHEN CAST(key_value AS VARCHAR) <> TRIM(CAST(key_value AS VARCHAR)) THEN 1 ELSE 0 END),
       COUNT(DISTINCT CAST(tipdoc AS VARCHAR))
FROM e_perm_aws.t_rsk_cta_sueldo
