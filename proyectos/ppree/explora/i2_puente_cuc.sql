-- ============================================================================
-- I2. R8 - t_mst_ctaibk_rsk devolvio len_min = 0: hay key_value vacios en el
--     puente CIF que sostiene TODO el perimetro reenganche. Cuantos, y cuanto
--     fan-out mete cod_cuc -> (key_value, tip_doc).
-- ============================================================================
WITH p AS (
  SELECT
    CAST(cod_cuc AS VARCHAR)     AS cod_cuc,
    CAST(key_value AS VARCHAR)   AS key_value,
    CAST(tip_doc AS VARCHAR)     AS tip_doc
  FROM e_perm_aws.t_mst_ctaibk_rsk
),
fan AS (
  SELECT cod_cuc, COUNT(*) AS n_filas, COUNT(DISTINCT key_value) AS n_key, COUNT(DISTINCT tip_doc) AS n_tipdoc
  FROM p
  GROUP BY 1
)
SELECT
  (SELECT COUNT(*) FROM p)                                                          AS n_puente,
  (SELECT COUNT(*) FROM p WHERE key_value IS NULL OR LENGTH(key_value) = 0)         AS n_key_vacio,
  (SELECT COUNT(*) FROM p WHERE LENGTH(key_value) NOT IN (0, 64))                   AS n_key_len_rara,
  (SELECT COUNT(*) FROM fan)                                                        AS n_cuc,
  (SELECT COUNT(*) FROM fan WHERE n_filas > 1)                                      AS n_cuc_multifila,
  (SELECT COUNT(*) FROM fan WHERE n_key > 1)                                        AS n_cuc_multikey,
  (SELECT COUNT(*) FROM fan WHERE n_tipdoc > 1)                                     AS n_cuc_multitipdoc,
  (SELECT COALESCE(MAX(n_filas), 0) FROM fan)                                       AS max_filas_por_cuc,
  (SELECT COUNT(*) FROM e_perm_aws.t_mrm_mongest_altas_pp_marcas_maa_tmp a
     WHERE a.subproducto = '1.REENGANCHE')                                          AS n_marca_ree,
  (SELECT COUNT(*) FROM e_perm_aws.t_mrm_mongest_altas_pp_marcas_maa_tmp a
     INNER JOIN p b ON CAST(a.cif_key AS VARCHAR) = b.cod_cuc
     WHERE a.subproducto = '1.REENGANCHE'
       AND (b.key_value IS NULL OR LENGTH(b.key_value) = 0))                        AS n_marca_ree_key_vacio
