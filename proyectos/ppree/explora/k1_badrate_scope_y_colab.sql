-- ============================================================================
-- K1. R6 - los dos badrate que faltan: el del RESTO (lo que excluye
--     filtro_scope_ree) y el de COLABORADOR. Ventana madura 202201-202506.
-- ============================================================================
WITH ree AS (
  SELECT DISTINCT CAST(B.key_value AS VARCHAR) AS key_value,
                  CAST(A.codmes_desembolso AS VARCHAR) AS codmes_mrm
  FROM d_perm_aws.t_mrm_mongest_altas_pp_marcas_maa_tmp A
  INNER JOIN e_perm_aws.t_mst_ctaibk_rsk B ON A.cif_key = B.cod_cuc
  WHERE A.subproducto = '1.REENGANCHE'
),
cl AS (
  SELECT DISTINCT CAST(periodo_gdh AS VARCHAR) AS codmes, CAST(key_value AS VARCHAR) AS key_value
  FROM e_perm_aws.t_colaboradores_gdh_rsk
  WHERE empresa = 'INTERBANK'
),
uni AS (
  SELECT
    SUBSTR(CAST(u.codmes_mrm AS VARCHAR), 1, 4)                                              AS anio,
    CAST(u.codmes_mrm AS VARCHAR)                                                            AS codmes_mrm,
    CAST(u.id_value AS VARCHAR)                                                              AS key_value,
    CASE WHEN r.key_value IS NOT NULL THEN 1 ELSE 0 END                                      AS flg_ree,
    CASE WHEN u.flg_rfnc_12m = 1 OR u.flg_cstg_12m = 1 OR u.max_dm_12m > 60 THEN 1 ELSE 0 END AS y12
  FROM e_perm_aws.ds_flg_compppibk_rsk u
  LEFT JOIN ree r
    ON CAST(u.id_value AS VARCHAR) = CAST(r.key_value AS VARCHAR)
   AND CAST(u.codmes_mrm AS VARCHAR) = r.codmes_mrm
  WHERE CAST(u.codmes_mrm AS INT) BETWEEN 202201 AND 202506
)
SELECT
  u.anio,
  COUNT(*)                                                                          AS n_universo,
  SUM(u.flg_ree)                                                                    AS n_ree,
  ROUND(AVG(CASE WHEN u.flg_ree = 1 THEN CAST(u.y12 AS DOUBLE) END), 4)             AS br_ree,
  ROUND(AVG(CASE WHEN u.flg_ree = 0 THEN CAST(u.y12 AS DOUBLE) END), 4)             AS br_resto,
  SUM(CASE WHEN c.key_value IS NOT NULL THEN 1 ELSE 0 END)                          AS n_colab,
  ROUND(AVG(CASE WHEN c.key_value IS NOT NULL THEN CAST(u.y12 AS DOUBLE) END), 4)   AS br_colab,
  SUM(CASE WHEN u.flg_ree = 1 AND c.key_value IS NOT NULL THEN 1 ELSE 0 END)        AS n_colab_ree
FROM uni u
LEFT JOIN cl c
  ON c.key_value = u.key_value
 AND c.codmes = DATE_FORMAT(DATE_PARSE(u.codmes_mrm, '%Y%m') - INTERVAL '2' MONTH, '%Y%m')
GROUP BY 1
ORDER BY 1
