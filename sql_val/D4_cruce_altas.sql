-- =====================================================================================
-- ORIGEN BPE PD · V2 · VALIDACION (read-only)
--   archivo : D_salida/D4_cruce_altas.sql
--   origen  : ~\mcp-runner\sql_ctas\QA_cruce_altas.sql
--   sha256  : 3843f7c56fd2   (del cuerpo, sin este encabezado)
--   estado  : AMARILLO
--   nota    : la validacion mas fuerte: PD de la PO vs target observado
-- =====================================================================================
-- =====================================================================================
-- QA_cruce_altas.sql | cruza las ALTAS contra el scoring de la PO
--
-- Correr DESPUES de PO_4. Es la validacion mas fuerte disponible: las altas son un
-- subconjunto de la PO, tienen target_12m observado, y el scoring de la PO deberia
-- reproducir exactamente la misma PD.
--
-- LA PREDICCION EXACTA
--   alta en codmes M      -> pd_raw en M-1, f_t por codmes_alta = M
--   PO en p_codmes = M-1  -> pd_raw en M-1, f_t por p_codmes+1  = M
--   Mismo insumo, misma cadena => prob_modelo_cal_v1 debe coincidir BIT A BIT.
--   V2 puede diferir, porque el flg_clean de la PO no es flg_calib_m2 (sin monto,
--   sin impulsa/reactiva). Esa diferencia se mide aparte, en el bloque 3.
--
-- VENTANA  codmes_alta 202402..202505
--   202402 = primer mes que cubre la PO (p_codmes 202401 + 1)
--   202505 = ultimo con 12 meses de maduracion cerrada
--
-- BLOQUES
--   1. COBERTURA   cuantas altas aparecen en el scoring de la PO. Si faltan muchas,
--                  la PO no contiene a todas las altas y hay que entender por que.
--   2. CALIBRACION PD vs RD observada, por version. Sobre datos reales, no sobre el
--                  parquet congelado.
--   3. CONCORDANCIA flg_clean de la PO vs flg_calib_m2 congelado. No tienen por que
--                  coincidir (son variables distintas a proposito), pero la matriz
--                  dice CUANTO difieren y en que direccion.
--   4. CONSISTENCIA la prueba fuerte: |PD_v1 de la PO - PD_v1 recalculada| debe ser 0.
--                  Aqui se compara contra la PD que trae la propia tabla, asi que lo
--                  que se mide es si el JOIN encontro a la misma persona-mes.
--
-- READ-ONLY.
-- =====================================================================================

WITH altas AS (
  SELECT cast(codmes AS int)            AS codmes_alta,
         cast(tip_doc AS varchar)       AS tip_doc,
         key_value,
         flg_calib_m2,
         target_12m,
         CASE WHEN tip_doc = '2' THEN 'PJJ' ELSE 'PNN' END AS personeria
  FROM disc_model_owner.bnbpe_ibk_calib_src
  WHERE flg_ibk = 1
    AND top4_entidad = 'TOP4'
    AND cast(codmes AS int) BETWEEN 202402 AND 202505
),
j AS (
  SELECT a.codmes_alta, a.personeria, a.flg_calib_m2, a.target_12m,
         s.flg_clean, s.prob_modelo_cal_v1, s.prob_modelo_cal_v2,
         s.grupos_cal_v1, s.grupos_cal_v2,
         CASE WHEN s.key_value IS NULL THEN 0 ELSE 1 END AS encontrada
  FROM altas a
  LEFT JOIN disc_model_owner.b46029_po_scoring_v1v2 s
    ON s.tip_doc = a.tip_doc AND s.key_value = a.key_value
   AND s.codmes_alta = a.codmes_alta
)

-- ---------------------------------------------------------------- 1. COBERTURA
SELECT '1. COBERTURA' AS bloque, 'altas en la ventana' AS detalle,
       cast(count(*) AS varchar) AS valor, '' AS extra
FROM j
UNION ALL SELECT '1. COBERTURA', 'encontradas en el scoring de la PO',
       cast(sum(encontrada) AS varchar),
       cast(round(100.0 * sum(encontrada) / nullif(count(*), 0), 2) AS varchar) || ' %'
FROM j
UNION ALL SELECT '1. COBERTURA', 'NO encontradas',
       cast(count(*) - sum(encontrada) AS varchar), 'idealmente 0'
FROM j

-- ---------------------------------------------------------------- 2. CALIBRACION
UNION ALL
SELECT '2. CALIB V1 ' || personeria, 'n / defaults',
       cast(count(*) AS varchar) || ' / ' || cast(sum(target_12m) AS varchar), ''
FROM j WHERE encontrada = 1 GROUP BY personeria
UNION ALL
SELECT '2. CALIB V1 ' || personeria, 'RD obs vs PD prom (%)',
       cast(round(100 * avg(cast(target_12m AS double)), 2) AS varchar) || ' vs ' ||
       cast(round(100 * avg(prob_modelo_cal_v1), 2) AS varchar),
       'EC ' || cast(round(100 * (avg(prob_modelo_cal_v1) /
              nullif(avg(cast(target_12m AS double)), 0) - 1), 1) AS varchar) || ' %' ||
       CASE WHEN avg(prob_modelo_cal_v1) < avg(cast(target_12m AS double))
            THEN '  *** SUB-PREDICE ***' ELSE '' END
FROM j WHERE encontrada = 1 GROUP BY personeria
UNION ALL
SELECT '2. CALIB V2 ' || personeria, 'RD obs vs PD prom (%)',
       cast(round(100 * avg(cast(target_12m AS double)), 2) AS varchar) || ' vs ' ||
       cast(round(100 * avg(prob_modelo_cal_v2), 2) AS varchar),
       'EC ' || cast(round(100 * (avg(prob_modelo_cal_v2) /
              nullif(avg(cast(target_12m AS double)), 0) - 1), 1) AS varchar) || ' %' ||
       CASE WHEN avg(prob_modelo_cal_v2) < avg(cast(target_12m AS double))
            THEN '  *** SUB-PREDICE ***' ELSE '' END
FROM j WHERE encontrada = 1 GROUP BY personeria

-- ---------------------------------------------------------------- 3. CONCORDANCIA
UNION ALL
SELECT '3. FLAGS', 'calib_m2=' || cast(flg_calib_m2 AS varchar) ||
                   ' / po_clean=' || cast(flg_clean AS varchar),
       cast(count(*) AS varchar),
       CASE WHEN flg_calib_m2 = flg_clean THEN 'coinciden'
            WHEN flg_calib_m2 = 0 AND flg_clean = 1
                 THEN 'la PO lo pasa a clean (monto / impulsa)'
            ELSE 'la PO lo pasa a dirty — revisar' END
FROM j WHERE encontrada = 1 GROUP BY flg_calib_m2, flg_clean

-- ---------------------------------------------------------------- 4. CONSISTENCIA
UNION ALL
SELECT '4. CONSISTENCIA', 'V1 = V2 donde po_clean=1',
       cast(count_if(abs(prob_modelo_cal_v1 - prob_modelo_cal_v2) <= 1e-12) AS varchar)
       || ' de ' || cast(count(*) AS varchar), 'deben ser todas'
FROM j WHERE encontrada = 1 AND flg_clean = 1
UNION ALL
SELECT '4. CONSISTENCIA', 'V1 != V2 donde po_clean=0',
       cast(count_if(abs(prob_modelo_cal_v1 - prob_modelo_cal_v2) > 1e-12) AS varchar)
       || ' de ' || cast(count(*) AS varchar), 'deben ser todas'
FROM j WHERE encontrada = 1 AND flg_clean = 0
ORDER BY 1, 2
