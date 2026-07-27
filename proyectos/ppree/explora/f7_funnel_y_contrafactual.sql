-- ============================================================================
-- F7. FUNNEL DE LA CASCADA (n_cascada) + CONTRAFACTUAL DEL TARGET, perimetro
--     reenganche, sobre la madre de produccion.
--     casc = dsc_flg_malo_12m='MALO'   red = flg_rfnc_12m/flg_cstg_12m/max_dm_12m>60
-- ============================================================================
WITH ree AS (
  SELECT DISTINCT B.key_value, A.codmes_desembolso
  FROM d_perm_aws.t_mrm_mongest_altas_pp_marcas_maa_tmp A
  INNER JOIN e_perm_aws.t_mst_ctaibk_rsk B ON A.cif_key = B.cod_cuc
  WHERE A.subproducto = '1.REENGANCHE'
),
uni AS (
  SELECT
    SUBSTR(CAST(u.codmes_mrm AS VARCHAR), 1, 4)                                              AS anio,
    u.dsc_flg_malo_12m                                                                       AS rama,
    CASE WHEN r.key_value IS NOT NULL THEN 1 ELSE 0 END                                      AS flg_ree,
    CASE WHEN u.dsc_flg_malo_12m = 'MALO' THEN 1 ELSE 0 END                                  AS y_casc,
    CASE WHEN u.flg_rfnc_12m = 1 OR u.flg_cstg_12m = 1 OR u.max_dm_12m > 60 THEN 1 ELSE 0 END AS y_red,
    CASE WHEN u.dsc_flg_malo_12m IN ('BUENO','MALO','INDETERMINADO','INSUFICIENTE') THEN 1 ELSE 0 END AS en_po
  FROM e_perm_aws.ds_flg_compppibk_rsk u
  LEFT JOIN ree r
    ON CAST(u.id_value AS VARCHAR) = CAST(r.key_value AS VARCHAR)
   AND CAST(u.codmes_mrm AS VARCHAR) = CAST(r.codmes_desembolso AS VARCHAR)
)
SELECT
  anio,
  COALESCE(rama, 'NULL')                                                    AS rama,
  SUM(flg_ree)                                                              AS n_ree,
  COUNT(*) - SUM(flg_ree)                                                   AS n_resto,
  SUM(CASE WHEN flg_ree = 1 AND y_casc = 1 AND y_red = 1 THEN 1 ELSE 0 END) AS n_11,
  SUM(CASE WHEN flg_ree = 1 AND y_casc = 1 AND y_red = 0 THEN 1 ELSE 0 END) AS n_10,
  SUM(CASE WHEN flg_ree = 1 AND y_casc = 0 AND y_red = 1 THEN 1 ELSE 0 END) AS n_01,
  SUM(CASE WHEN flg_ree = 1 AND en_po = 1 THEN 1 ELSE 0 END)                AS n_ree_po
FROM uni
GROUP BY 1, 2
ORDER BY 1, 2
