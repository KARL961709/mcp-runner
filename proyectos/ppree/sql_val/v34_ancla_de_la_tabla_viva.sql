-- ============================================================================
-- v34. QUE ANCLA TIENE pd_raw DE LA TABLA VIVA, MES POR MES
--
--   v33 cerro la pregunta del parquet: empata pd_en_M1 en las siete cohortes,
--   asi que el parquet de reenganche new lleva el ancla VIEJA (M+1). Queda la
--   pregunta que decide si el export 96 sirve: la tabla gobernada
--   ds_stk_ree_pp_cal, de donde 96 saca pd_raw, con que ancla quedo.
--
--   v30 probo codmes_mrm sobre 49,430 filas, que NO es todo el perimetro
--   (~106k). Si la fuente se poblo mes con mes solo en los meses recientes, el
--   ancla puede ser MIXTA por mes y v30 habria mirado justo el tramo bueno.
--   Por eso aca no va un promedio: va identidad FILA A FILA contra los dos
--   meses candidatos, y agrupada por mes para que una mezcla se vea.
--
--   LECTURA:
--     n_igual_M  = n_pd_raw en TODOS los meses -> ancla codmes_mrm, 96 sirve
--     n_igual_M1 = n_pd_raw en TODOS los meses -> ancla M+1, 96 hereda el error
--     mezcla por mes                           -> la tabla viva esta partida
--
--   La fuente se agrega por llave antes del join: un LEFT JOIN a una tabla
--   deduplicada no puede inflar filas, asi que n_filas es el perimetro real.
-- ============================================================================
WITH src AS (
  SELECT CAST(cod_mes AS VARCHAR)            AS mes,
         CAST(cod_tip_doc AS VARCHAR)        AS tip_doc,
         CAST(key_value AS VARCHAR)          AS id_value,
         MAX(CAST(prob_modelo AS DOUBLE))    AS pd
  FROM disc_model_owner.scr_stk_ree_pp_cal_2023_202610
  WHERE prob_modelo IS NOT NULL
  GROUP BY 1, 2, 3
),
pob AS (
  SELECT CAST(codmes_mrm AS VARCHAR)  AS mes_mrm,
         CAST(codmes_scr AS VARCHAR)  AS mes_scr,
         CAST(tip_doc AS VARCHAR)     AS tip_doc,
         CAST(id_value AS VARCHAR)    AS id_value,
         CAST(pd_raw AS DOUBLE)       AS pd_raw
  FROM disc_model_owner.ds_stk_ree_pp_cal
  WHERE flg_scope_ree = 1
)
SELECT p.mes_mrm                                                              AS cohorte,
       COUNT(*)                                                               AS n_filas,
       COUNT(p.pd_raw)                                                        AS n_pd_raw,
       COUNT(a.pd)                                                            AS n_src_M,
       COUNT(b.pd)                                                            AS n_src_M1,
       SUM(CASE WHEN p.pd_raw IS NOT NULL AND a.pd IS NOT NULL
                 AND ABS(p.pd_raw - a.pd) < 1e-12 THEN 1 ELSE 0 END)          AS n_igual_M,
       SUM(CASE WHEN p.pd_raw IS NOT NULL AND b.pd IS NOT NULL
                 AND ABS(p.pd_raw - b.pd) < 1e-12 THEN 1 ELSE 0 END)          AS n_igual_M1,
       ROUND(100.0 * AVG(p.pd_raw), 4)                                        AS pd_raw_media
FROM pob p
LEFT JOIN src a
       ON a.mes = p.mes_mrm AND a.tip_doc = p.tip_doc AND a.id_value = p.id_value
LEFT JOIN src b
       ON b.mes = p.mes_scr AND b.tip_doc = p.tip_doc AND b.id_value = p.id_value
GROUP BY p.mes_mrm
ORDER BY 1
