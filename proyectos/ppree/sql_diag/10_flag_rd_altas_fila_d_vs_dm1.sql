-- ============================================================================
-- 10. TABLA FLAG OFICIAL: TARGET 12M DE LAS ALTAS EN LA FILA FOTO D vs FOTO D-1
-- ============================================================================
WITH mar AS (
  SELECT DISTINCT
    CAST(b.key_value AS VARCHAR)         AS key_value,
    CAST(a.codmes_desembolso AS VARCHAR) AS d
  FROM d_perm_aws.t_mrm_mongest_altas_pp_marcas_maa_tmp a
  INNER JOIN e_perm_aws.t_mst_ctaibk_rsk b
    ON CAST(a.cif_key AS VARCHAR) = CAST(b.cod_cuc AS VARCHAR)
  WHERE a.subproducto = '1.REENGANCHE'
    AND LENGTH(CAST(b.key_value AS VARCHAR)) = 64
    AND CAST(a.codmes_desembolso AS VARCHAR) BETWEEN '202202' AND '202506'
),
f AS (
  SELECT CAST(codmes_mrm AS VARCHAR) AS codmes_mrm, CAST(id_value AS VARCHAR) AS key_value,
         MAX(dsc_flg_malo_12m) AS flg
  FROM e_perm_aws.ds_flg_compppibk_rsk
  GROUP BY 1, 2
),
u AS (
  SELECT SUBSTR(m.d, 1, 4) AS anio, '1_fila_foto_D (ventana D+1..D+12)' AS version, f0.flg AS flg
  FROM mar m
  LEFT JOIN f f0 ON f0.key_value = m.key_value AND f0.codmes_mrm = m.d
  UNION ALL
  SELECT SUBSTR(m.d, 1, 4) AS anio, '2_fila_foto_D-1 (ventana D..D+11)' AS version, f1.flg AS flg
  FROM mar m
  LEFT JOIN f f1 ON f1.key_value = m.key_value
               AND f1.codmes_mrm = DATE_FORMAT(DATE_ADD('month', -1, DATE_PARSE(m.d, '%Y%m')), '%Y%m')
)
SELECT
  anio,
  version,
  COUNT(*)                                                                   AS n_altas,
  COUNT_IF(flg IS NULL)                                                      AS n_sin_fila,
  COUNT_IF(flg = 'MALO')                                                     AS n_malo,
  COUNT_IF(flg = 'BUENO')                                                    AS n_bueno,
  COUNT_IF(flg = 'INDETERMINADO')                                            AS n_indet,
  COUNT_IF(flg = 'INSUFICIENTE')                                             AS n_insuf,
  COUNT_IF(flg NOT IN ('MALO','BUENO','INDETERMINADO','INSUFICIENTE'))       AS n_excluido,
  ROUND(COUNT_IF(flg = 'MALO') * 1.0
        / NULLIF(COUNT_IF(flg IN ('MALO','BUENO','INDETERMINADO','INSUFICIENTE')), 0), 4) AS rd12
FROM u
GROUP BY 1, 2
ORDER BY 1, 2
