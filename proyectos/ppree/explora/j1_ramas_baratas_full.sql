-- ============================================================================
-- J1. R6 - n POR CODMES DE LAS 5 RAMAS QUE NO TOCAN RCC, VENTANA COMPLETA,
--     predicados AISLADOS sobre el perimetro reenganche (marca, A14/A17).
--     El badrate sale de la madre donde existe (202201+); antes queda NULL.
-- ============================================================================
WITH ree AS (
  SELECT DISTINCT CAST(B.key_value AS VARCHAR) AS key_value,
                  CAST(A.codmes_desembolso AS VARCHAR) AS codmes_mrm
  FROM d_perm_aws.t_mrm_mongest_altas_pp_marcas_maa_tmp A
  INNER JOIN e_perm_aws.t_mst_ctaibk_rsk B ON A.cif_key = B.cod_cuc
  WHERE A.subproducto = '1.REENGANCHE'
    AND CAST(A.codmes_desembolso AS INT) BETWEEN 201901 AND 202606
),
dm0 AS (
  SELECT CAST(codmes AS VARCHAR) AS codmes, CAST(key_value AS VARCHAR) AS key_value,
         MAX(dm) AS dm_max,
         SUM(COALESCE(vig, 0) + COALESCE(ven, 0) + COALESCE(jud, 0) + COALESCE(castigado, 0)) AS saldo_tot
  FROM e_perm_aws.t_rsk_bkp_cierre_mensual
  WHERE CAST(codmes AS INT) BETWEEN 201901 AND 202606
    AND prod LIKE '06%' AND (subprod IS NULL OR subprod <> 'Cre.Efec.GH') AND aplicativo = 'HPC'
  GROUP BY 1, 2
),
gh AS (
  SELECT DISTINCT CAST(codmes AS VARCHAR) AS codmes, CAST(key_value AS VARCHAR) AS key_value
  FROM e_perm_aws.t_rsk_bkp_cierre_mensual
  WHERE CAST(codmes AS INT) BETWEEN 201901 AND 202606
    AND prod = '06 Cred efectivo' AND subprod = 'Cre.Efec.GH'
),
rf AS (
  SELECT DISTINCT CAST(codmes AS VARCHAR) AS codmes, CAST(key_value AS VARCHAR) AS key_value
  FROM e_perm_aws.t_rsk_bkp_cierre_mensual
  WHERE CAST(codmes AS INT) BETWEEN 201901 AND 202606
    AND prod LIKE '08%' AND subprod LIKE '06%' AND aplicativo = 'HPC'
),
cst AS (
  SELECT DISTINCT DATE_FORMAT(a.ingreso_cj_fc, '%Y%m') AS codmes, CAST(c.key_value AS VARCHAR) AS key_value
  FROM e_perm_aws.t_sco_maestro_cl_rsk a
  INNER JOIN e_perm_aws.t_mst_ctaibk_rsk c ON a.cod_cuc = c.cod_cuc
  WHERE DATE_FORMAT(a.ingreso_cj_fc, '%Y%m') BETWEEN '201901' AND '202606'
),
cl AS (
  SELECT DISTINCT CAST(periodo_gdh AS VARCHAR) AS codmes, CAST(key_value AS VARCHAR) AS key_value
  FROM e_perm_aws.t_colaboradores_gdh_rsk
  WHERE empresa = 'INTERBANK'
),
mad AS (
  SELECT CAST(codmes_mrm AS VARCHAR) AS codmes_mrm, CAST(id_value AS VARCHAR) AS key_value,
         MAX(CASE WHEN flg_rfnc_12m = 1 OR flg_cstg_12m = 1 OR max_dm_12m > 60 THEN 1 ELSE 0 END) AS y12
  FROM e_perm_aws.ds_flg_compppibk_rsk
  GROUP BY 1, 2
)
SELECT
  r.codmes_mrm,
  COUNT(*)                                                                                AS n_perimetro,
  ROUND(AVG(CAST(m.y12 AS DOUBLE)), 4)                                                    AS br_universo,
  SUM(CASE WHEN g.key_value IS NOT NULL THEN 1 ELSE 0 END)                                AS n_gtia_hip,
  ROUND(AVG(CASE WHEN g.key_value IS NOT NULL THEN CAST(m.y12 AS DOUBLE) END), 4)         AS br_gtia_hip,
  SUM(CASE WHEN cl.key_value IS NOT NULL THEN 1 ELSE 0 END)                               AS n_colab,
  SUM(CASE WHEN d.dm_max > 60 OR rf.key_value IS NOT NULL OR c.key_value IS NOT NULL THEN 1 ELSE 0 END) AS n_malo_origen,
  ROUND(AVG(CASE WHEN d.dm_max > 60 OR rf.key_value IS NOT NULL OR c.key_value IS NOT NULL THEN CAST(m.y12 AS DOUBLE) END), 4) AS br_malo_origen,
  SUM(CASE WHEN d.key_value IS NOT NULL AND d.saldo_tot = 0 THEN 1 ELSE 0 END)            AS n_mto_pend,
  SUM(CASE WHEN d.key_value IS NULL THEN 1 ELSE 0 END)                                    AS n_baja
FROM ree r
LEFT JOIN dm0 d ON d.key_value = r.key_value AND d.codmes = r.codmes_mrm
LEFT JOIN gh  g ON g.key_value = r.key_value AND g.codmes = r.codmes_mrm
LEFT JOIN rf    ON rf.key_value = r.key_value AND rf.codmes = r.codmes_mrm
LEFT JOIN cst c ON c.key_value = r.key_value AND c.codmes = r.codmes_mrm
LEFT JOIN cl    ON cl.key_value = r.key_value
              AND cl.codmes = DATE_FORMAT(DATE_PARSE(r.codmes_mrm, '%Y%m') - INTERVAL '2' MONTH, '%Y%m')
LEFT JOIN mad m ON m.key_value = r.key_value AND m.codmes_mrm = r.codmes_mrm
GROUP BY 1
ORDER BY 1
