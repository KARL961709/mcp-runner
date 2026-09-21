-- desemb_grupos_2502_2508.sql | tablas de grupos (general + drivers PN/PJ/NUEVO/RECURRENTE) sobre cosechas 202502-202508, universo calib. Reaplica overlay REC (PJ_REC 0.72/PN_REC 0.82) sobre pd_pit y recalcula grupo con cortes 971/945/921/908/893 (la maestra trae overlay viejo PJ 0.85). RD12 solo maduras (meses_madurez=12). Read-only, agregado.
WITH base AS (
  SELECT cod_mes, cod_tip_doc, desc_cliente, meses_madurez, target_12m,
    CASE WHEN cod_tip_doc = '1' THEN 'PN' ELSE 'PJ' END AS per,
    GREATEST(1e-6, LEAST(1-1e-6, pd_pit * CASE
      WHEN cod_tip_doc = '2' AND desc_cliente = 'RECURRENTE' THEN 0.72
      WHEN cod_tip_doc = '1' AND desc_cliente = 'RECURRENTE' THEN 0.82
      ELSE 1.0 END)) AS prob_rec
  FROM disc_model_owner.b46029_desemb_maestra_202609
  WHERE flg_cruce = 1 AND flg_universo_calib = 1 AND cod_mes BETWEEN 202502 AND 202508
),
g AS (
  SELECT base.*,
    CAST(round((1.0 - prob_rec) * 1000) AS INTEGER) AS pt
  FROM base
),
gg AS (
  SELECT g.*,
    CASE WHEN pt >= 971 THEN 'G1' WHEN pt >= 945 THEN 'G2' WHEN pt >= 921 THEN 'G3'
         WHEN pt >= 908 THEN 'G4' WHEN pt >= 893 THEN 'G5' ELSE 'G6' END AS grupo
  FROM g
)
SELECT
  CASE WHEN GROUPING(per) = 0 THEN per WHEN GROUPING(desc_cliente) = 0 THEN desc_cliente ELSE 'GENERAL' END AS driver,
  grupo,
  COUNT(*) AS n,
  COUNT(CASE WHEN meses_madurez = 12 THEN 1 END) AS n_mad,
  ROUND(100 * AVG(prob_rec), 2) AS pd_all_pct,
  ROUND(100 * AVG(CASE WHEN meses_madurez = 12 THEN prob_rec END), 2) AS pd_mad_pct,
  ROUND(100 * AVG(CASE WHEN meses_madurez = 12 THEN target_12m END), 2) AS rd12_pct
FROM gg
GROUP BY GROUPING SETS ((grupo), (per, grupo), (desc_cliente, grupo))
ORDER BY driver, grupo
