-- ============================================================================
-- E7. CONTRAFACTUAL DEL TARGET: cascada vs rederivado (matriz 2x2 + delta RD)
--     cascada    = dsc_flg_malo_12m = 'MALO'                (lo vigente)
--     rederivado = flg_rfnc_12m=1 OR flg_cstg_12m=1 OR max_dm_12m > 60
--     La diferencia son las 6 ramas duras, que la cascada devuelve como 0.
-- ============================================================================
WITH ree AS (
  SELECT DISTINCT B.key_value, A.codmes_desembolso
  FROM d_perm_aws.t_mrm_mongest_altas_pp_marcas_maa_tmp A
  INNER JOIN e_perm_aws.t_mst_ctaibk_rsk B ON A.cif_key = B.cod_cuc
  WHERE A.subproducto = '1.REENGANCHE'
),
uni AS (
  SELECT
    CAST(u.codmes_mrm AS VARCHAR)                                                            AS codmes_mrm,
    u.dsc_flg_malo_12m,
    CASE WHEN u.dsc_flg_malo_12m = 'MALO' THEN 1 ELSE 0 END                                  AS y_casc,
    CASE WHEN u.flg_rfnc_12m = 1 OR u.flg_cstg_12m = 1 OR u.max_dm_12m > 60 THEN 1 ELSE 0 END AS y_red,
    CASE WHEN u.dsc_flg_malo_12m IN ('BUENO','MALO','INDETERMINADO','INSUFICIENTE') THEN 1 ELSE 0 END AS en_po
  FROM disc_model_owner.enr_ds_flg_compppibk_rsk u
  INNER JOIN ree r
    ON CAST(u.id_value AS VARCHAR) = CAST(r.key_value AS VARCHAR)
   AND CAST(u.codmes_mrm AS VARCHAR) = CAST(r.codmes_desembolso AS VARCHAR)
)
SELECT
  SUBSTR(codmes_mrm, 1, 4)                                                  AS anio,
  COUNT(*)                                                                  AS n_universo,
  SUM(en_po)                                                                AS n_po_vigente,
  COUNT(*) - SUM(en_po)                                                     AS n_ramas_duras,
  SUM(CASE WHEN y_casc = 1 AND y_red = 1 THEN 1 ELSE 0 END)                 AS n_11,
  SUM(CASE WHEN y_casc = 1 AND y_red = 0 THEN 1 ELSE 0 END)                 AS n_10,
  SUM(CASE WHEN y_casc = 0 AND y_red = 1 THEN 1 ELSE 0 END)                 AS n_01,
  SUM(CASE WHEN y_casc = 0 AND y_red = 0 THEN 1 ELSE 0 END)                 AS n_00,
  ROUND(100.0 * SUM(CASE WHEN en_po = 1 THEN y_casc END) / NULLIF(SUM(en_po), 0), 4) AS rd_vigente_pct,
  ROUND(100.0 * AVG(CAST(y_red AS DOUBLE)), 4)                              AS rd_rederivado_pct,
  SUM(CASE WHEN dsc_flg_malo_12m = 'INSUFICIENTE' THEN 1 ELSE 0 END)        AS n_insuficiente,
  SUM(CASE WHEN dsc_flg_malo_12m = 'INDETERMINADO' THEN 1 ELSE 0 END)       AS n_indeterminado
FROM uni
GROUP BY 1
ORDER BY 1
