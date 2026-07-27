-- ============================================================================
-- L1. O3 y O11 - CONTRAFACTUAL DE LOS DOS PREDICADOS QUE ESCRIBI MAL.
--     baja   Recibido: existe fila en t0 CON cuc nulo   (ENR.sql#L238)
--            mio:      NO existe fila en t0             (la negacion)
--     mto    Recibido: MAX por cuenta -> alguna cuenta en cero (ENR.sql#L237)
--            mio:      SUM por cliente -> saldo total cero
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
  SELECT
    CAST(codmes AS VARCHAR)                                                   AS codmes,
    CAST(key_value AS VARCHAR)                                                AS key_value,
    COUNT(*)                                                                  AS n_cuentas,
    SUM(CASE WHEN cuc IS NULL THEN 1 ELSE 0 END)                              AS n_cuc_nulo,
    MAX(CASE WHEN COALESCE(vig,0)+COALESCE(ven,0)+COALESCE(jud,0)+COALESCE(castigado,0) = 0 THEN 1 ELSE 0 END) AS flg_alguna_cta_cero,
    SUM(COALESCE(vig,0)+COALESCE(ven,0)+COALESCE(jud,0)+COALESCE(castigado,0)) AS saldo_tot
  FROM e_perm_aws.t_rsk_bkp_cierre_mensual
  WHERE CAST(codmes AS INT) BETWEEN 201901 AND 202606
    AND prod LIKE '06%' AND (subprod IS NULL OR subprod <> 'Cre.Efec.GH') AND aplicativo = 'HPC'
  GROUP BY 1, 2
)
SELECT
  SUBSTR(r.codmes_mrm, 1, 4)                                                        AS anio,
  COUNT(*)                                                                          AS n_perimetro,
  SUM(CASE WHEN d.key_value IS NOT NULL AND d.n_cuc_nulo > 0 THEN 1 ELSE 0 END)     AS baja_recibido,
  SUM(CASE WHEN d.key_value IS NULL THEN 1 ELSE 0 END)                              AS baja_mio,
  SUM(CASE WHEN d.flg_alguna_cta_cero = 1 THEN 1 ELSE 0 END)                        AS mto_recibido,
  SUM(CASE WHEN d.key_value IS NOT NULL AND d.saldo_tot = 0 THEN 1 ELSE 0 END)      AS mto_mio,
  SUM(CASE WHEN d.n_cuentas > 1 THEN 1 ELSE 0 END)                                  AS n_multicuenta,
  ROUND(AVG(CAST(d.n_cuentas AS DOUBLE)), 3)                                        AS prom_cuentas
FROM ree r
LEFT JOIN dm0 d ON d.key_value = r.key_value AND d.codmes = r.codmes_mrm
GROUP BY 1
ORDER BY 1
