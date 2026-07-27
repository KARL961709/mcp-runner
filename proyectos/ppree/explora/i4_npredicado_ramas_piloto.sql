-- ============================================================================
-- I4. R4 - n_PREDICADO DE LAS 6 RAMAS DURAS, AISLADAS, SOBRE EL PERIMETRO
--     COMPLETO (no la cascada, que sub-cuenta). Piloto 202301-202306: mide
--     tambien el coste de la cadena que va a usar N5 (R10).
--     Perimetro = marca reenganche (A14), dedup a (key_value, codmes_mrm).
-- ============================================================================
WITH ree AS (
  SELECT DISTINCT CAST(B.key_value AS VARCHAR) AS key_value,
                  CAST(A.codmes_desembolso AS VARCHAR) AS codmes_mrm
  FROM d_perm_aws.t_mrm_mongest_altas_pp_marcas_maa_tmp A
  INNER JOIN e_perm_aws.t_mst_ctaibk_rsk B ON A.cif_key = B.cod_cuc
  WHERE A.subproducto = '1.REENGANCHE'
    AND CAST(A.codmes_desembolso AS INT) BETWEEN 202301 AND 202306
),
dm0 AS (
  SELECT CAST(codmes AS VARCHAR) AS codmes, CAST(key_value AS VARCHAR) AS key_value,
         MAX(dm) AS dm_max,
         SUM(COALESCE(vig, 0) + COALESCE(ven, 0) + COALESCE(jud, 0) + COALESCE(castigado, 0)) AS saldo_tot
  FROM e_perm_aws.t_rsk_bkp_cierre_mensual
  WHERE CAST(codmes AS INT) BETWEEN 202301 AND 202306
    AND prod LIKE '06%' AND (subprod IS NULL OR subprod <> 'Cre.Efec.GH') AND aplicativo = 'HPC'
  GROUP BY 1, 2
),
gh AS (
  SELECT DISTINCT CAST(codmes AS VARCHAR) AS codmes, CAST(key_value AS VARCHAR) AS key_value
  FROM e_perm_aws.t_rsk_bkp_cierre_mensual
  WHERE CAST(codmes AS INT) BETWEEN 202301 AND 202306
    AND prod = '06 Cred efectivo' AND subprod = 'Cre.Efec.GH'
),
rf AS (
  SELECT DISTINCT CAST(codmes AS VARCHAR) AS codmes, CAST(key_value AS VARCHAR) AS key_value
  FROM e_perm_aws.t_rsk_bkp_cierre_mensual
  WHERE CAST(codmes AS INT) BETWEEN 202301 AND 202306
    AND prod LIKE '08%' AND subprod LIKE '06%' AND aplicativo = 'HPC'
),
cs AS (
  SELECT DISTINCT DATE_FORMAT(a.ingreso_cj_fc, '%Y%m') AS codmes, CAST(c.key_value AS VARCHAR) AS key_value
  FROM e_perm_aws.t_sco_maestro_cl_rsk a
  INNER JOIN e_perm_aws.t_mst_ctaibk_rsk c ON a.cod_cuc = c.cod_cuc
  WHERE DATE_FORMAT(a.ingreso_cj_fc, '%Y%m') BETWEEN '202301' AND '202306'
),
cl AS (
  SELECT DISTINCT CAST(periodo_gdh AS VARCHAR) AS codmes, CAST(key_value AS VARCHAR) AS key_value
  FROM e_perm_aws.t_colaboradores_gdh_rsk
  WHERE CAST(periodo_gdh AS INT) BETWEEN 202211 AND 202304
    AND empresa = 'INTERBANK'
),
sf AS (
  SELECT DATE_FORMAT(DATE_PARSE(codmes, '%Y%m') + INTERVAL '1' MONTH, '%Y%m') AS codmes,
         CAST(key_value AS VARCHAR) AS key_value,
         MAX(CAST(condicion AS DOUBLE)) AS cond_max
  FROM e_perm_aws.t_fact_report_rcc_rsk
  WHERE CAST(codmes AS INT) BETWEEN 202212 AND 202305
    AND SUBSTR(cod_cuenta_rcc, 1, 2) = '14'
    AND SUBSTR(cod_cuenta_rcc, 4, 1) IN ('1', '3', '4', '5', '6')
    AND tipo_credito IN ('01','02','03','04','05','06','07','08','09','10','11','12','13')
  GROUP BY 1, 2
)
SELECT
  r.codmes_mrm,
  COUNT(*)                                                                                AS n_perimetro,
  SUM(CASE WHEN g.key_value IS NOT NULL THEN 1 ELSE 0 END)                                AS n_gtia_hip,
  SUM(CASE WHEN cl.key_value IS NOT NULL THEN 1 ELSE 0 END)                               AS n_colab,
  SUM(CASE WHEN s.cond_max > 60 THEN 1 ELSE 0 END)                                        AS n_malo_sf,
  SUM(CASE WHEN d.dm_max > 60 OR rf.key_value IS NOT NULL OR c.key_value IS NOT NULL THEN 1 ELSE 0 END) AS n_malo_origen,
  SUM(CASE WHEN d.key_value IS NOT NULL AND d.saldo_tot = 0 THEN 1 ELSE 0 END)            AS n_mto_pend,
  SUM(CASE WHEN d.key_value IS NULL THEN 1 ELSE 0 END)                                    AS n_baja
FROM ree r
LEFT JOIN dm0 d ON d.key_value = r.key_value AND d.codmes = r.codmes_mrm
LEFT JOIN gh  g ON g.key_value = r.key_value AND g.codmes = r.codmes_mrm
LEFT JOIN rf    ON rf.key_value = r.key_value AND rf.codmes = r.codmes_mrm
LEFT JOIN cs  c ON c.key_value = r.key_value AND c.codmes = r.codmes_mrm
LEFT JOIN cl    ON cl.key_value = r.key_value
              AND cl.codmes = DATE_FORMAT(DATE_PARSE(r.codmes_mrm, '%Y%m') - INTERVAL '2' MONTH, '%Y%m')
LEFT JOIN sf  s ON s.key_value = r.key_value AND s.codmes = r.codmes_mrm
GROUP BY 1
ORDER BY 1
