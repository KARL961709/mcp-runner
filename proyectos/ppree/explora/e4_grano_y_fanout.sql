-- ============================================================================
-- E4. U7 - GRANO Y FAN-OUT: duplicados en la madre, en la marca, y tras el join
-- ============================================================================
WITH d_madre AS (
  SELECT codmes_mrm, tip_doc, id_value, COUNT(*) AS n
  FROM disc_model_owner.enr_ds_flg_compppibk_rsk
  GROUP BY 1, 2, 3
  HAVING COUNT(*) > 1
),
ree AS (
  SELECT DISTINCT B.key_value, A.codmes_desembolso
  FROM d_perm_aws.t_mrm_mongest_altas_pp_marcas_maa_tmp A
  INNER JOIN e_perm_aws.t_mst_ctaibk_rsk B ON A.cif_key = B.cod_cuc
  WHERE A.subproducto = '1.REENGANCHE'
),
d_ree AS (
  SELECT key_value, codmes_desembolso, COUNT(*) AS n
  FROM ree
  GROUP BY 1, 2
  HAVING COUNT(*) > 1
),
post AS (
  SELECT COUNT(*) AS n_post
  FROM disc_model_owner.enr_ds_flg_compppibk_rsk u
  LEFT JOIN ree r
    ON CAST(u.id_value AS VARCHAR) = CAST(r.key_value AS VARCHAR)
   AND CAST(u.codmes_mrm AS VARCHAR) = CAST(r.codmes_desembolso AS VARCHAR)
)
SELECT
  (SELECT COUNT(*) FROM disc_model_owner.enr_ds_flg_compppibk_rsk)            AS n_madre,
  (SELECT COUNT(*) FROM d_madre)                                             AS n_llaves_dup_madre,
  (SELECT COALESCE(SUM(n), 0) FROM d_madre)                                  AS n_filas_dup_madre,
  (SELECT COALESCE(MAX(n), 0) FROM d_madre)                                  AS max_dup_madre,
  (SELECT COUNT(*) FROM ree)                                                 AS n_marca_ree,
  (SELECT COUNT(*) FROM d_ree)                                               AS n_llaves_dup_ree,
  (SELECT n_post FROM post)                                                  AS n_post_join,
  (SELECT n_post FROM post) - (SELECT COUNT(*) FROM disc_model_owner.enr_ds_flg_compppibk_rsk) AS delta_fanout
