-- ============================================================================
-- I3. U2 - CONFIRMACION DIRECTA DEL ANCLA DE LA v4.
--     Los conteos de g3 igualan exacto a la madre en codmes_mrm+1 los 29 meses,
--     y g4 mostro que a igual codmes los flg_reenganche casi no coinciden.
--     Aqui se prueba contra la MARCA (A14), que es quien define el perimetro:
--     A = v4.codmes vs codmes_mrm      B = v4.codmes vs codmes_mrm + 1
-- ============================================================================
WITH ree AS (
  SELECT DISTINCT CAST(B.key_value AS VARCHAR) AS key_value, CAST(A.codmes_desembolso AS VARCHAR) AS codmes_mrm
  FROM d_perm_aws.t_mrm_mongest_altas_pp_marcas_maa_tmp A
  INNER JOIN e_perm_aws.t_mst_ctaibk_rsk B ON A.cif_key = B.cod_cuc
  WHERE A.subproducto = '1.REENGANCHE'
    AND CAST(A.codmes_desembolso AS INT) BETWEEN 202401 AND 202512
),
v4 AS (
  SELECT CAST(codmes AS VARCHAR) AS codmes, CAST(key_value AS VARCHAR) AS key_value,
         CAST(flg_reenganche AS INTEGER) AS flg_ree
  FROM disc_riesgos.t_b39918_scr_stockpp_itc_reen_reprocesov4
  WHERE CAST(codmes AS INT) BETWEEN 202401 AND 202601
)
SELECT
  SUBSTR(r.codmes_mrm, 1, 4)                                                     AS anio,
  COUNT(*)                                                                       AS n_marca,
  SUM(CASE WHEN a.key_value IS NOT NULL THEN 1 ELSE 0 END)                       AS n_cruce_A,
  SUM(CASE WHEN b.key_value IS NOT NULL THEN 1 ELSE 0 END)                       AS n_cruce_B,
  SUM(CASE WHEN a.flg_ree = 1 THEN 1 ELSE 0 END)                                 AS n_flgree_A,
  SUM(CASE WHEN b.flg_ree = 1 THEN 1 ELSE 0 END)                                 AS n_flgree_B
FROM ree r
LEFT JOIN v4 a ON a.key_value = r.key_value AND a.codmes = r.codmes_mrm
LEFT JOIN v4 b ON b.key_value = r.key_value
              AND b.codmes = DATE_FORMAT(DATE_PARSE(r.codmes_mrm, '%Y%m') + INTERVAL '1' MONTH, '%Y%m')
GROUP BY 1
ORDER BY 1
