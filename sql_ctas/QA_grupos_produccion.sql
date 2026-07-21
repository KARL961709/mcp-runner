-- =====================================================================================
-- QA_grupos_produccion.sql | ¿los grupos DE LA TABLA FINAL ordenan el riesgo?
--
-- Correr DESPUES de PO_4. La pregunta es sobre b46029_po_scoring_v1v2 — la tabla que
-- va a produccion — no sobre parquets locales. Pero esa tabla no trae target: es la
-- PO, no altas. Asi que se cruza con bnbpe_ibk_calib_src, que si tiene target_12m.
--
-- El resultado es la RD observada por grupo, LEYENDO EL GRUPO DE LA TABLA FINAL.
-- Si sale monotona, los grupos sirven para ranking y campania aunque el nivel de PD
-- este descalibrado.
--
-- SE ABRE POR ANIO A PROPOSITO
--   Hay un quiebre estructural entre 2023 y 2024: la RD del mismo perimetro cae de
--   13.86% a 4.33% y se queda ahi, sin que el pd_raw se mueva. El nivel se rompe,
--   pero en los parquets locales el ORDEN aguanta en los 5 periodos (Gini 0.32-0.47).
--   Esto verifica lo mismo sobre la tabla que se va a usar.
--
-- VENTANA  codmes_alta 202402..202505
--   202402 = primer mes que cubre la PO ·  202505 = ultimo con 12m cerrados
--   Son ~11 meses de 2024 y 5 de 2025.
--
-- COMO SE LEE
--   rd_pct debe CRECER de G1 a G5 dentro de cada anio y version.
--   Un quiebre en un grupo con n chico es ruido; en uno grande es senial.
--   La columna pd_prom_pct al lado dice cuanto sobre-predice cada grupo.
--
-- READ-ONLY.
-- =====================================================================================

WITH altas AS (
  SELECT cast(codmes AS int)      AS codmes_alta,
         cast(tip_doc AS varchar) AS tip_doc,
         key_value,
         target_12m
  FROM disc_model_owner.bnbpe_ibk_calib_src
  WHERE flg_ibk = 1
    AND top4_entidad = 'TOP4'
    AND cast(codmes AS int) BETWEEN 202402 AND 202505
),
j AS (
  SELECT cast(a.codmes_alta / 100 AS varchar) AS anio,
         a.target_12m,
         s.grupos_cal_v1, s.grupos_cal_v2,
         s.prob_modelo_cal_v1, s.prob_modelo_cal_v2
  FROM altas a
  JOIN disc_model_owner.b46029_po_scoring_v1v2 s
    ON s.tip_doc = a.tip_doc AND s.key_value = a.key_value
   AND s.codmes_alta = a.codmes_alta
)

SELECT 'V1' AS version, anio, grupos_cal_v1 AS grupo,
       count(*)                                          AS n,
       sum(target_12m)                                   AS defaults,
       round(100.0 * avg(cast(target_12m AS double)), 2) AS rd_pct,
       round(100.0 * avg(prob_modelo_cal_v1), 2)         AS pd_prom_pct
FROM j GROUP BY anio, grupos_cal_v1

UNION ALL
SELECT 'V1', 'TOTAL', grupos_cal_v1,
       count(*), sum(target_12m),
       round(100.0 * avg(cast(target_12m AS double)), 2),
       round(100.0 * avg(prob_modelo_cal_v1), 2)
FROM j GROUP BY grupos_cal_v1

UNION ALL
SELECT 'V2', anio, grupos_cal_v2,
       count(*), sum(target_12m),
       round(100.0 * avg(cast(target_12m AS double)), 2),
       round(100.0 * avg(prob_modelo_cal_v2), 2)
FROM j GROUP BY anio, grupos_cal_v2

UNION ALL
SELECT 'V2', 'TOTAL', grupos_cal_v2,
       count(*), sum(target_12m),
       round(100.0 * avg(cast(target_12m AS double)), 2),
       round(100.0 * avg(prob_modelo_cal_v2), 2)
FROM j GROUP BY grupos_cal_v2

ORDER BY 1, 2, 3
