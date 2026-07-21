-- =====================================================================================
-- SCORING_PO_V1V2.sql | PO completa con las DOS versiones — MATERIALIZA
--
-- ESCRIBE: crea disc_model_owner.b46029_po_scoring_v1v2, particionada por p_codmes.
--   Son ~4.2M filas por mes: devolverlas a un CSV no sirve para nada. Se materializa,
--   como hace q7_scoring_po_cal.sql con scr_admbankbpe_po_cal.
--   p_codmes va ULTIMO en el SELECT porque Athena exige que las columnas de particion
--   sean las finales.
--   Si ya existe: DROP TABLE disc_model_owner.b46029_po_scoring_v1v2
--
-- Generado por generar_sql_po_v1v2.py. NO editar constantes: regenerar.
--
-- USO
--   {P_INI} {P_FIN}    rango de p_codmes ('YYYYMM'). Rango valido: '202206'..'202607'
--   {TABLA_FLAGS}       tabla con (codmes, tip_doc, key_value, flg_clean) para la PO,
--                        producida por FLAGS_DESDE_MADRE.sql sobre esta misma poblacion.
--                        codmes de esa tabla = codmes_alta = p_codmes + 1.
--
-- CAMPOS
--   prob_modelo            pd_raw original del scorecard
--   prob_modelo_cal_v1     cadena CLEAN aplicada a TODOS
--   puntuacion_cal_v1      round((1 - prob_modelo_cal_v1) * 1000)
--   grupos_cal_v1          cortes [964, 942, 919, 820]   optimizados sobre altas para V1
--   flg_clean              0 o 1, NUNCA NULL (ver nota)
--   prob_modelo_cal_v2     cadena propia de cada bloque, enrutada por flg_clean
--   puntuacion_cal_v2      round((1 - prob_modelo_cal_v2) * 1000)
--   grupos_cal_v2          cortes [961, 939, 914, 819]   optimizados sobre altas para V2
--
-- flg_clean NUNCA ES NULL: el LEFT JOIN a {TABLA_FLAGS} usa coalesce(...,1). Un cliente
--   sin fila en esa tabla no tiene evidencia de knockout, y ausencia de knockout es
--   clean por definicion del AND. OJO: eso solo es correcto si {TABLA_FLAGS} se
--   construyo sobre TODA la poblacion que se esta puntuando. Si se construyo sobre un
--   subconjunto, el resto entra como clean por omision — que es la direccion INSEGURA
--   (V1 sub-predice sobre dirty). Verificar cobertura antes de confiar en V2.
--
-- CORTES: no son el apetito BN, son OPTIMOS por version sobre altas 202207-202505
--   (min MAE vs apetito, monotonia, materialidad 15%). V1 MAE 2.75pp, V2 MAE 2.64pp.
--   Los cortes del apetito [976,954,933,900] dan MAE 4.16 y 4.27 respectivamente.
--
-- ⚠ EXTRAPOLACION: la calibracion se ajusto sobre ALTAS ADMITIDAS. El pd_raw de la PO
--   llega a ~0.87 contra ~0.5 en altas. La cola alta no tiene evidencia detras.
-- =====================================================================================
CREATE TABLE disc_model_owner.b46029_po_scoring_v1v2
WITH (format='PARQUET', parquet_compression='SNAPPY', partitioned_by=ARRAY['p_codmes']) AS

WITH ft (codmes_alta, fhat, meses_usados) AS ( VALUES
  (202207, 0.46731627731126968, 3),
  (202208, 0.056728699947162099, 3),
  (202209, -0.38935742968535247, 3),
  (202210, -0.70072994178821002, 3),
  (202211, -0.85205451520464348, 3),
  (202212, -0.92891552347195483, 3),
  (202301, -1.0159184358416815, 3),
  (202302, -1.0379535945181364, 3),
  (202303, -1.0609231368183629, 3),
  (202304, -1.105625425606386, 3),
  (202305, -1.1568688592667788, 3),
  (202306, -1.1568688592667788, 3),
  (202307, -0.94596279749778256, 3),
  (202308, -0.51623687799565809, 3),
  (202309, -0.030103544427882899, 3),
  (202310, 0.32449026737520231, 3),
  (202311, 0.52946365930378281, 3),
  (202312, 0.68472846461918047, 3),
  (202401, 0.88376877419346278, 3),
  (202402, 1.0779696991599816, 3),
  (202403, 1.2044927251923596, 3),
  (202404, 1.201179762312532, 3),
  (202405, 1.1457097080976519, 3),
  (202406, 1.104751202610557, 3),
  (202407, 1.1060161144381395, 3),
  (202408, 1.1019902137713098, 3),
  (202409, 1.1002452201190325, 3),
  (202410, 1.1875559465718, 3),
  (202411, 1.3180022720336295, 3),
  (202412, 1.4595914586518206, 3),
  (202501, 1.5193331146887308, 3),
  (202502, 1.5295598659038827, 3),
  (202503, 1.5467370500137263, 3),
  (202504, 1.6703824334712063, 3),
  (202505, 1.8720398724011265, 3),
  (202506, 2.0194314436566057, 3),
  (202507, 2.0194314436566057, 3),
  (202508, 2.0194314436566057, 3),
  (202509, 2.0194314436566057, 3),
  (202510, 2.0194314436566057, 3),
  (202511, 2.0194314436566057, 3),
  (202512, 2.0194314436566057, 3),
  (202601, 2.0194314436566057, 3),
  (202602, 2.0194314436566057, 3),
  (202603, 2.0194314436566057, 3),
  (202604, 1.9724204666385832, 3),
  (202605, 1.4715585841909371, 3),
  (202606, 0.8175440736248093, 3),
  (202607, 0.2008886726564256, 3),
  (202608, -0.021384045860002102, 3),
  (202609, -0.034594450720994298, 2)
),
b AS (
  SELECT cast(tip_doc AS varchar) AS tip_doc, key_value,
         cast(p_codmes AS int) AS p_codmes, max(probabilidad) AS pd_raw
  FROM e_perm_aws.scr_admbankbpe_rsk
  WHERE p_codmes BETWEEN '202606' AND '202606'
  GROUP BY 1,2,3
),
fl AS (
  SELECT cast(codmes AS int) AS codmes, cast(tip_doc AS varchar) AS tip_doc, key_value,
         max(flg_clean) AS flg_clean
  FROM disc_model_owner.b46029_po_flg_clean
  GROUP BY 1,2,3
),
base AS (
  SELECT b.p_codmes,
         cast(date_format(date_parse(cast(b.p_codmes AS varchar),'%Y%m')
                          + interval '1' month,'%Y%m') AS int) AS codmes_alta,
         b.tip_doc, b.key_value,
         CASE WHEN b.tip_doc = '2' THEN 'PJJ' ELSE 'PNN' END AS personeria,
         greatest(1e-6, least(1-1e-6, b.pd_raw)) AS pd_raw,
         f.fhat, f.meses_usados AS ft_meses_usados,
         cast(coalesce(fl.flg_clean, 1) AS integer) AS flg_clean
  FROM b
  JOIN ft f
    ON f.codmes_alta = cast(date_format(date_parse(cast(b.p_codmes AS varchar),'%Y%m')
                                        + interval '1' month,'%Y%m') AS int)
  LEFT JOIN fl
    ON fl.tip_doc = b.tip_doc AND fl.key_value = b.key_value
   AND fl.codmes  = cast(date_format(date_parse(cast(b.p_codmes AS varchar),'%Y%m')
                                     + interval '1' month,'%Y%m') AS int)
  WHERE b.pd_raw IS NOT NULL
),
niv_cln AS (
  SELECT b.*, greatest(1e-6, least(1-1e-6,
    CASE WHEN b.personeria = 'PNN'
      THEN 1.0/(1.0 + exp(-( -0.72488396139167532 + 0.63943961553578943*ln(b.pd_raw) + -1.0325848544388896*ln(1.0-b.pd_raw) )))
      ELSE 1.0/(1.0 + exp(-( 0.17759688908412222 + 1.058477056441401*(ln(b.pd_raw) - ln(1.0-b.pd_raw)) ))) END )) AS pd_cal
  FROM base b
),
rho_cln AS (
  SELECT n.*, greatest(0.001, least(0.999,
    0.035978817268325414 * ( 0.03*((1 - exp(-35*n.pd_cal))/(1 - exp(-35.0)))
            + 0.16*(1 - (1 - exp(-35*n.pd_cal))/(1 - exp(-35.0))) )
    / CASE WHEN n.personeria = 'PNN' THEN 0.035560752391369591 ELSE 0.03634808815365035 END )) AS rho_i
  FROM niv_cln n
),
pit_cln AS (
  SELECT r.*, greatest(1e-6, least(1-1e-6,
    normal_cdf(0, 1, (inverse_normal_cdf(0, 1, r.pd_cal)
                      - sqrt(r.rho_i) * 0.34999999999999998 * r.fhat) / sqrt(1.0 - r.rho_i))
    * CASE WHEN r.personeria = 'PNN' THEN 1.1306030131221239 ELSE 1.1073857212572329 END )) AS pd_pit
  FROM rho_cln r
),
niv_dty AS (
  SELECT b.*, greatest(1e-6, least(1-1e-6,
    CASE WHEN b.personeria = 'PNN'
      THEN 1.0/(1.0 + exp(-( -0.15676765088130001 + 0.64162444955106612*ln(b.pd_raw) + 0.083173096581749414*ln(1.0-b.pd_raw) )))
      ELSE 1.0/(1.0 + exp(-( -0.60971743608471285 + 0.85566792258078261*(ln(b.pd_raw) - ln(1.0-b.pd_raw)) ))) END )) AS pd_cal
  FROM base b
),
rho_dty AS (
  SELECT n.*, greatest(0.001, least(0.999,
    0.035978817268325414 * ( 0.03*((1 - exp(-35*n.pd_cal))/(1 - exp(-35.0)))
            + 0.16*(1 - (1 - exp(-35*n.pd_cal))/(1 - exp(-35.0))) )
    / CASE WHEN n.personeria = 'PNN' THEN 0.030343535251014398 ELSE 0.036801943015635719 END )) AS rho_i
  FROM niv_dty n
),
pit_dty AS (
  SELECT r.*, greatest(1e-6, least(1-1e-6,
    normal_cdf(0, 1, (inverse_normal_cdf(0, 1, r.pd_cal)
                      - sqrt(r.rho_i) * 0.34999999999999998 * r.fhat) / sqrt(1.0 - r.rho_i))
    * CASE WHEN r.personeria = 'PNN' THEN 1.0801021982671937 ELSE 1.1207211368581367 END )) AS pd_pit
  FROM rho_dty r
)

SELECT
  c.codmes_alta, c.tip_doc, c.key_value, c.personeria,
  c.pd_raw            AS prob_modelo,
  c.fhat, c.ft_meses_usados,

  -- ---------- V1: cadena CLEAN para todos ----------
  c.pd_pit                                        AS prob_modelo_cal_v1,
  cast(round((1.0 - c.pd_pit) * 1000) AS integer) AS puntuacion_cal_v1,
  CASE WHEN round((1.0 - c.pd_pit) * 1000) >= 964 THEN 'G1' WHEN round((1.0 - c.pd_pit) * 1000) >= 942 THEN 'G2' WHEN round((1.0 - c.pd_pit) * 1000) >= 919 THEN 'G3' WHEN round((1.0 - c.pd_pit) * 1000) >= 820 THEN 'G4' ELSE 'G5' END                                            AS grupos_cal_v1,

  c.flg_clean,

  -- ---------- V2: cada bloque con la suya ----------
  CASE WHEN c.flg_clean = 1 THEN c.pd_pit ELSE d.pd_pit END AS prob_modelo_cal_v2,
  cast(round((1.0 - CASE WHEN c.flg_clean = 1 THEN c.pd_pit ELSE d.pd_pit END) * 1000)
       AS integer)                                          AS puntuacion_cal_v2,
  CASE WHEN round((1.0 - CASE WHEN c.flg_clean = 1 THEN c.pd_pit ELSE d.pd_pit END) * 1000) >= 961 THEN 'G1' WHEN round((1.0 - CASE WHEN c.flg_clean = 1 THEN c.pd_pit ELSE d.pd_pit END) * 1000) >= 939 THEN 'G2' WHEN round((1.0 - CASE WHEN c.flg_clean = 1 THEN c.pd_pit ELSE d.pd_pit END) * 1000) >= 914 THEN 'G3' WHEN round((1.0 - CASE WHEN c.flg_clean = 1 THEN c.pd_pit ELSE d.pd_pit END) * 1000) >= 819 THEN 'G4' ELSE 'G5' END                                                      AS grupos_cal_v2,

  -- p_codmes AL FINAL: Athena exige que las columnas de particion sean las ultimas
  c.p_codmes
FROM pit_cln c
JOIN pit_dty d
  ON d.p_codmes = c.p_codmes AND d.tip_doc = c.tip_doc AND d.key_value = c.key_value
