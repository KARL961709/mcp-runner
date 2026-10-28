-- v15_matriz_flgree_d_vs_d1.sql | el JOINT de flg_reenganche en archivo D x D+1
-- Read-only. Max 9 filas. 08 da las marginales; el joint no se deriva de ellas, y
-- es lo que dice cuanto pesa cada caso de v14. Lleva el saldo PP al cierre D-1 y D
-- por celda: ahi se ve si el desembolso ya aterrizo en la foto.
WITH mar AS (
  SELECT DISTINCT
    CAST(b.key_value AS VARCHAR)         AS key_value,
    CAST(a.codmes_desembolso AS VARCHAR) AS d
  FROM d_perm_aws.t_mrm_mongest_altas_pp_marcas_maa_tmp a
  INNER JOIN e_perm_aws.t_mst_ctaibk_rsk b
    ON CAST(a.cif_key AS VARCHAR) = CAST(b.cod_cuc AS VARCHAR)
  WHERE a.subproducto = '1.REENGANCHE'
    AND LENGTH(CAST(b.key_value AS VARCHAR)) = 64
    AND CAST(a.codmes_desembolso AS VARCHAR) BETWEEN '202401' AND '202506'
),
v AS (
  SELECT CAST(key_value AS VARCHAR)           AS key_value,
         CAST(codmes AS VARCHAR)              AS codmes,
         MAX(pd_comppp_reen_itc)              AS pd,
         MAX(CAST(flg_reenganche AS INTEGER)) AS flg_ree
  FROM disc_riesgos.t_b39918_scr_stockpp_itc_reen_reprocesov4
  WHERE CAST(codmes AS VARCHAR) BETWEEN '202401' AND '202507'
  GROUP BY 1, 2
),
c AS (
  SELECT CAST(codmes AS VARCHAR)    AS codmes,
         CAST(key_value AS VARCHAR) AS key_value,
         SUM(COALESCE(CAST(deuda_vig_sol AS DOUBLE), 0)
           + COALESCE(CAST(deuda_ven_sol AS DOUBLE), 0)
           + COALESCE(CAST(deuda_jud_sol AS DOUBLE), 0)) AS saldo
  FROM e_perm_aws.t_rsk_bkp_cierre_mensual
  WHERE CAST(codmes AS INT) BETWEEN 202312 AND 202506
    AND prod LIKE '06%' AND (subprod IS NULL OR subprod <> 'Cre.Efec.GH') AND aplicativo = 'HPC'
  GROUP BY 1, 2
),
j AS (
  SELECT
    CASE WHEN vd.pd  IS NULL THEN '3_sin_fila' WHEN vd.flg_ree  = 1 THEN '2_flg_1' ELSE '1_flg_0' END AS archivo_d,
    CASE WHEN vd1.pd IS NULL THEN '3_sin_fila' WHEN vd1.flg_ree = 1 THEN '2_flg_1' ELSE '1_flg_0' END AS archivo_d1,
    vd.pd  AS pd_d,
    vd1.pd AS pd_d1,
    cm1.saldo AS saldo_dm1,
    c0.saldo  AS saldo_d
  FROM mar m
  LEFT JOIN v vd  ON vd.key_value  = m.key_value AND vd.codmes  = m.d
  LEFT JOIN v vd1 ON vd1.key_value = m.key_value
                 AND vd1.codmes = DATE_FORMAT(DATE_ADD('month', 1, DATE_PARSE(m.d, '%Y%m')), '%Y%m')
  LEFT JOIN c cm1 ON cm1.key_value = m.key_value
                 AND cm1.codmes = DATE_FORMAT(DATE_ADD('month', -1, DATE_PARSE(m.d, '%Y%m')), '%Y%m')
  LEFT JOIN c c0  ON c0.key_value = m.key_value AND c0.codmes = m.d
)
SELECT
  archivo_d                                                           AS flgree_archivo_d,
  archivo_d1                                                          AS flgree_archivo_d1,
  COUNT(*)                                                            AS n_altas,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)                  AS pct,
  ROUND(AVG(pd_d), 5)                                                 AS pd_media_d,
  ROUND(AVG(pd_d1), 5)                                                AS pd_media_d1,
  ROUND(APPROX_PERCENTILE(saldo_dm1, 0.5), 0)                         AS saldo_mediano_cierre_dm1,
  ROUND(APPROX_PERCENTILE(saldo_d, 0.5), 0)                           AS saldo_mediano_cierre_d,
  ROUND(APPROX_PERCENTILE(saldo_d / NULLIF(saldo_dm1, 0), 0.5), 3)    AS ratio_saldo_d_sobre_dm1
FROM j
GROUP BY 1, 2
ORDER BY 3 DESC
