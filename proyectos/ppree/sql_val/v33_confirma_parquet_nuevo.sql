-- ============================================================================
-- v33. CONFIRMA SI EL PARQUET NUEVO ES CORRECTO. Siete cohortes, dos anclas.
--
--   Para cada cohorte se pide la pd media de la fuente sobre los MISMOS
--   clientes del perimetro, en los dos meses candidatos:
--     pd_en_M   = cod_mes = codmes_mrm   -> mes con mes   (50_pd nuevo, correcto)
--     pd_en_M1  = cod_mes = codmes_scr   -> M+1           (50_pd viejo)
--
--   LO QUE TRAE EL PARQUET (medido local, flg_scope_ree = 1, pd no nula):
--     cohorte   n       pd media
--     202212    1,750   35.8949 pct
--     202301    1,853   33.7897 pct
--     202306    1,743   34.3284 pct
--     202312    1,075   27.4649 pct
--     202406      949   21.6898 pct
--     202506    1,701   19.9629 pct
--     202509    2,009   20.2479 pct
--
--   VEREDICTO: la columna que empate a cuatro decimales en las SIETE dice que
--   ancla uso el export. Dos meses consecutivos de la fuente difieren medio
--   punto o mas (v23), asi que siete empates no son casualidad.
--   Si pd_en_M empata  -> el parquet nuevo ES correcto, mes con mes.
--   Si pd_en_M1 empata -> el parquet nuevo lleva el ancla vieja.
--   n_en_M = 0 en la cohorte 202212 confirma ademas que la fuente arranca en
--   202301, que es lo que midio v28.
-- ============================================================================
WITH pob AS (
  SELECT DISTINCT
         CAST(codmes_mrm AS VARCHAR) AS mes_mrm,
         CAST(codmes_scr AS VARCHAR) AS mes_scr,
         CAST(tip_doc AS VARCHAR)    AS tip_doc,
         CAST(id_value AS VARCHAR)   AS id_value
  FROM disc_model_owner.ds_stk_ree_pp_cal
  WHERE flg_scope_ree = 1
    AND codmes_mrm IN ('202212', '202301', '202306', '202312', '202406', '202506', '202509')
),
src AS (
  SELECT CAST(cod_mes AS VARCHAR)     AS mes,
         CAST(cod_tip_doc AS VARCHAR) AS tip_doc,
         CAST(key_value AS VARCHAR)   AS id_value,
         CAST(prob_modelo AS DOUBLE)  AS pd
  FROM disc_model_owner.scr_stk_ree_pp_cal_2023_202610
  WHERE prob_modelo IS NOT NULL
)
SELECT p.mes_mrm                                  AS cohorte,
       COUNT(*)                                   AS n_pob,
       COUNT(a.pd)                                AS n_en_M,
       ROUND(100.0 * AVG(a.pd), 4)                AS pd_en_M,
       COUNT(b.pd)                                AS n_en_M1,
       ROUND(100.0 * AVG(b.pd), 4)                AS pd_en_M1
FROM pob p
LEFT JOIN src a
       ON a.mes = p.mes_mrm AND a.tip_doc = p.tip_doc AND a.id_value = p.id_value
LEFT JOIN src b
       ON b.mes = p.mes_scr AND b.tip_doc = p.tip_doc AND b.id_value = p.id_value
GROUP BY p.mes_mrm
ORDER BY 1
