-- v14_casos_alta_traza.sql | CASOS: una alta por estrato, trazada D-2..D+1
-- Read-only. 6 estratos x 4 meses = 24 filas. Sin key_value en la salida: el caso
-- se identifica por su estrato. Mes de desembolso fijado en 202502 (dentro de la
-- ventana de calibracion, RD12 cerrada).
WITH mar AS (
  SELECT DISTINCT
    CAST(b.key_value AS VARCHAR)         AS key_value,
    CAST(a.codmes_desembolso AS VARCHAR) AS d
  FROM d_perm_aws.t_mrm_mongest_altas_pp_marcas_maa_tmp a
  INNER JOIN e_perm_aws.t_mst_ctaibk_rsk b
    ON CAST(a.cif_key AS VARCHAR) = CAST(b.cod_cuc AS VARCHAR)
  WHERE a.subproducto = '1.REENGANCHE'
    AND LENGTH(CAST(b.key_value AS VARCHAR)) = 64
    AND CAST(a.codmes_desembolso AS VARCHAR) = '202502'
),
v AS (
  SELECT CAST(key_value AS VARCHAR)            AS key_value,
         CAST(codmes AS VARCHAR)               AS codmes,
         MAX(pd_comppp_reen_itc)               AS pd,
         MAX(CAST(flg_reenganche AS INTEGER))  AS flg_ree
  FROM disc_riesgos.t_b39918_scr_stockpp_itc_reen_reprocesov4
  WHERE CAST(codmes AS VARCHAR) IN ('202412', '202501', '202502', '202503')
  GROUP BY 1, 2
),
c AS (
  SELECT CAST(codmes AS VARCHAR)    AS codmes,
         CAST(key_value AS VARCHAR) AS key_value,
         COUNT(*)                   AS n_ctas,
         MAX(dm)                    AS dm_max,
         SUM(COALESCE(CAST(deuda_vig_sol AS DOUBLE), 0)
           + COALESCE(CAST(deuda_ven_sol AS DOUBLE), 0)
           + COALESCE(CAST(deuda_jud_sol AS DOUBLE), 0)) AS saldo
  FROM e_perm_aws.t_rsk_bkp_cierre_mensual
  WHERE CAST(codmes AS INT) IN (202412, 202501, 202502, 202503)
    AND prod LIKE '06%' AND (subprod IS NULL OR subprod <> 'Cre.Efec.GH') AND aplicativo = 'HPC'
  GROUP BY 1, 2
),
f AS (
  SELECT CAST(codmes_mrm AS VARCHAR)  AS codmes_mrm,
         CAST(id_value AS VARCHAR)    AS key_value,
         MAX(CAST(codmes AS VARCHAR)) AS codmes_madre,
         MAX(dsc_flg_malo_12m)        AS flg12
  FROM e_perm_aws.ds_flg_compppibk_rsk
  WHERE CAST(codmes_mrm AS VARCHAR) IN ('202412', '202501', '202502', '202503')
  GROUP BY 1, 2
),
base AS (
  SELECT m.key_value, m.d,
         vd.pd  AS pd_d,  vd.flg_ree  AS flg_d,
         vd1.pd AS pd_d1, vd1.flg_ree AS flg_d1
  FROM mar m
  LEFT JOIN v vd  ON vd.key_value  = m.key_value AND vd.codmes  = m.d
  LEFT JOIN v vd1 ON vd1.key_value = m.key_value
                 AND vd1.codmes = DATE_FORMAT(DATE_ADD('month', 1, DATE_PARSE(m.d, '%Y%m')), '%Y%m')
),
est AS (
  SELECT key_value, d,
         CASE WHEN flg_d = 1                          THEN 'A_flgree_ya_en_D'
              WHEN pd_d  IS NULL AND pd_d1 IS NOT NULL THEN 'B_sin_fila_en_D'
              WHEN pd_d1 IS NULL AND pd_d  IS NOT NULL THEN 'C_sin_fila_en_D1'
              WHEN pd_d1 < pd_d                        THEN 'D_pd_baja_post'
              WHEN pd_d1 > pd_d                        THEN 'E_pd_sube_post'
              ELSE                                          'F_pd_igual_o_sin_dato'
         END AS estrato
  FROM base
),
pick AS (
  SELECT estrato, key_value, d,
         ROW_NUMBER() OVER (PARTITION BY estrato ORDER BY key_value) AS rn
  FROM est
),
cal AS (
  SELECT p.estrato, p.key_value, p.d, t.rel, t.k
  FROM pick p
  CROSS JOIN UNNEST(ARRAY['1_D-2', '2_D-1', '3_D_desembolso', '4_D+1'],
                    ARRAY[-2, -1, 0, 1]) AS t(rel, k)
  WHERE p.rn = 1
)
SELECT
  cal.estrato                                                              AS caso,
  cal.rel                                                                  AS mes_rel,
  DATE_FORMAT(DATE_ADD('month', cal.k, DATE_PARSE(cal.d, '%Y%m')), '%Y%m') AS codmes,
  ROUND(v.pd, 6)                                                           AS pd_v4,
  v.flg_ree                                                                AS flgree_v4,
  c.n_ctas                                                                 AS n_ctas_pp,
  ROUND(c.saldo, 0)                                                        AS saldo_pp,
  c.dm_max                                                                 AS dias_mora,
  f.codmes_madre                                                           AS madre_codmes,
  f.flg12                                                                  AS madre_flg_malo_12m
FROM cal
LEFT JOIN v ON v.key_value = cal.key_value
           AND v.codmes = DATE_FORMAT(DATE_ADD('month', cal.k, DATE_PARSE(cal.d, '%Y%m')), '%Y%m')
LEFT JOIN c ON c.key_value = cal.key_value
           AND c.codmes = DATE_FORMAT(DATE_ADD('month', cal.k, DATE_PARSE(cal.d, '%Y%m')), '%Y%m')
LEFT JOIN f ON f.key_value = cal.key_value
           AND f.codmes_mrm = DATE_FORMAT(DATE_ADD('month', cal.k, DATE_PARSE(cal.d, '%Y%m')), '%Y%m')
ORDER BY 1, 2
