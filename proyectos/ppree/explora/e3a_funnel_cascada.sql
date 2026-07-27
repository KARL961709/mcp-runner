-- ============================================================================
-- E3a. FUNNEL DE LA CASCADA POR ANIO Y PERIMETRO  (n_cascada, no n_predicado)
--      Las 6 ramas duras son residuales por construccion: este `n` SUB-CUENTA.
-- ============================================================================
WITH ree AS (
  SELECT DISTINCT B.key_value, A.codmes_desembolso
  FROM d_perm_aws.t_mrm_mongest_altas_pp_marcas_maa_tmp A
  INNER JOIN e_perm_aws.t_mst_ctaibk_rsk B ON A.cif_key = B.cod_cuc
  WHERE A.subproducto = '1.REENGANCHE'
),
uni AS (
  SELECT
    u.codmes_mrm,
    u.dsc_flg_malo_12m,
    CASE WHEN r.key_value IS NOT NULL THEN 1 ELSE 0 END AS flg_ree
  FROM disc_model_owner.enr_ds_flg_compppibk_rsk u
  LEFT JOIN ree r
    ON CAST(u.id_value AS VARCHAR) = CAST(r.key_value AS VARCHAR)
   AND CAST(u.codmes_mrm AS VARCHAR) = CAST(r.codmes_desembolso AS VARCHAR)
)
SELECT
  SUBSTR(CAST(codmes_mrm AS VARCHAR), 1, 4)                        AS anio,
  COALESCE(dsc_flg_malo_12m, 'NULL')                               AS rama,
  SUM(CASE WHEN flg_ree = 1 THEN 1 ELSE 0 END)                     AS n_reenganche,
  SUM(CASE WHEN flg_ree = 0 THEN 1 ELSE 0 END)                     AS n_resto
FROM uni
GROUP BY 1, 2
ORDER BY 1, 2
