-- ============================================================================
-- E2b. U1 - FALSACION CONTRA COLUMNA INDEPENDIENTE
--      `condicion` (RCC, t0-1) vs `nro_dm_m00` (HPC cierre mensual, t0).
--      Si ambas son dias de atraso, la concordancia de tramo debe ser alta y
--      el desacuerdo simetrico. Si no lo es, `condicion` no es lo que se asume.
-- ============================================================================
WITH rcc AS (
  SELECT
    DATE_FORMAT(DATE_PARSE(codmes, '%Y%m') + INTERVAL '1' MONTH, '%Y%m') AS codmes_mrm,
    key_value,
    tip_doc,
    MAX(CAST(condicion AS DOUBLE))                                       AS cond_max
  FROM e_perm_aws.t_fact_report_rcc_rsk
  WHERE codmes IN ('202311', '202505')
    AND SUBSTR(cod_cuenta_rcc, 1, 2) = '14'
    AND SUBSTR(cod_cuenta_rcc, 4, 1) IN ('1', '3', '4', '5', '6')
    AND tipo_credito IN ('01','02','03','04','05','06','07','08','09','10','11','12','13')
  GROUP BY 1, 2, 3
),
mad AS (
  SELECT codmes_mrm, id_value AS key_value, tip_doc, MAX(nro_dm_m00) AS dm00
  FROM disc_model_owner.enr_ds_flg_compppibk_rsk
  WHERE codmes_mrm IN ('202312', '202506')
  GROUP BY 1, 2, 3
)
SELECT
  m.codmes_mrm,
  COUNT(*)                                                                    AS n_madre,
  SUM(CASE WHEN r.key_value IS NOT NULL THEN 1 ELSE 0 END)                    AS n_con_rcc,
  ROUND(CORR(CAST(m.dm00 AS DOUBLE), r.cond_max), 4)                          AS corr_dm00_cond,
  SUM(CASE WHEN m.dm00 = 0 AND r.cond_max = 0 THEN 1 ELSE 0 END)              AS n_ambos_cero,
  SUM(CASE WHEN m.dm00 > 60 AND r.cond_max > 60 THEN 1 ELSE 0 END)            AS n_ambos_mayor60,
  SUM(CASE WHEN m.dm00 > 60 AND r.cond_max <= 60 THEN 1 ELSE 0 END)           AS n_solo_dm00,
  SUM(CASE WHEN m.dm00 <= 60 AND r.cond_max > 60 THEN 1 ELSE 0 END)           AS n_solo_cond,
  ROUND(AVG(r.cond_max), 2)                                                   AS cond_prom,
  ROUND(AVG(CAST(m.dm00 AS DOUBLE)), 2)                                       AS dm00_prom
FROM mad m
LEFT JOIN rcc r
  ON  m.codmes_mrm = r.codmes_mrm
  AND CAST(m.key_value AS VARCHAR) = CAST(r.key_value AS VARCHAR)
  AND CAST(m.tip_doc AS VARCHAR)   = CAST(r.tip_doc AS VARCHAR)
GROUP BY 1
ORDER BY 1
