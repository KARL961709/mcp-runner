-- ============================================================================
-- G1. FRONTERA DE MADUREZ POR HORIZONTE, MEDIDA (no declarada por literal).
--     Ultimo codmes_mrm en que el mes futuro N no esta 100% ausente.
-- ============================================================================
WITH b AS (
  SELECT
    CAST(codmes_mrm AS VARCHAR)                                    AS codmes_mrm,
    COUNT(*)                                                       AS n,
    SUM(CASE WHEN nro_dm_m01 IS NULL THEN 1 ELSE 0 END)            AS s01,
    SUM(CASE WHEN nro_dm_m02 IS NULL THEN 1 ELSE 0 END)            AS s02,
    SUM(CASE WHEN nro_dm_m03 IS NULL THEN 1 ELSE 0 END)            AS s03,
    SUM(CASE WHEN nro_dm_m04 IS NULL THEN 1 ELSE 0 END)            AS s04,
    SUM(CASE WHEN nro_dm_m05 IS NULL THEN 1 ELSE 0 END)            AS s05,
    SUM(CASE WHEN nro_dm_m06 IS NULL THEN 1 ELSE 0 END)            AS s06,
    SUM(CASE WHEN nro_dm_m07 IS NULL THEN 1 ELSE 0 END)            AS s07,
    SUM(CASE WHEN nro_dm_m08 IS NULL THEN 1 ELSE 0 END)            AS s08,
    SUM(CASE WHEN nro_dm_m09 IS NULL THEN 1 ELSE 0 END)            AS s09,
    SUM(CASE WHEN nro_dm_m10 IS NULL THEN 1 ELSE 0 END)            AS s10,
    SUM(CASE WHEN nro_dm_m11 IS NULL THEN 1 ELSE 0 END)            AS s11,
    SUM(CASE WHEN nro_dm_m12 IS NULL THEN 1 ELSE 0 END)            AS s12
  FROM e_perm_aws.ds_flg_compppibk_rsk
  GROUP BY 1
)
SELECT  1 AS h, MAX(codmes_mrm) AS ult_maduro, COUNT(*) AS n_meses_maduros FROM b WHERE s01 < n
UNION ALL SELECT  2, MAX(codmes_mrm), COUNT(*) FROM b WHERE s02 < n
UNION ALL SELECT  3, MAX(codmes_mrm), COUNT(*) FROM b WHERE s03 < n
UNION ALL SELECT  4, MAX(codmes_mrm), COUNT(*) FROM b WHERE s04 < n
UNION ALL SELECT  5, MAX(codmes_mrm), COUNT(*) FROM b WHERE s05 < n
UNION ALL SELECT  6, MAX(codmes_mrm), COUNT(*) FROM b WHERE s06 < n
UNION ALL SELECT  7, MAX(codmes_mrm), COUNT(*) FROM b WHERE s07 < n
UNION ALL SELECT  8, MAX(codmes_mrm), COUNT(*) FROM b WHERE s08 < n
UNION ALL SELECT  9, MAX(codmes_mrm), COUNT(*) FROM b WHERE s09 < n
UNION ALL SELECT 10, MAX(codmes_mrm), COUNT(*) FROM b WHERE s10 < n
UNION ALL SELECT 11, MAX(codmes_mrm), COUNT(*) FROM b WHERE s11 < n
UNION ALL SELECT 12, MAX(codmes_mrm), COUNT(*) FROM b WHERE s12 < n
ORDER BY 1
