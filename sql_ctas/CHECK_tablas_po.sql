-- =====================================================================================
-- CHECK_tablas_po.sql | ¿que etapas de la PO existen y con cuantas filas?
--
-- Correr despues de cada CTAS. Un CTAS que reporta 404 al descargar puede haber
-- funcionado igual: el fallo esta en el `aws s3 cp`, no en la ejecucion.
--
-- Descomentar SOLO la linea de la tabla que quieras comprobar — Athena ejecuta una
-- sentencia por vez, asi que no se pueden encadenar.
--
-- READ-ONLY.
-- =====================================================================================

SELECT 'b46029_po_flg_rcc' AS tabla,
       count(*)                                  AS filas,
       count(DISTINCT codmes)                    AS meses,
       min(codmes)                               AS mes_min,
       max(codmes)                               AS mes_max,
       count(DISTINCT tip_doc || '|' || key_value) AS clientes,
       sum(flg_impulsa_bwd)                      AS con_impulsa,
       sum(flg_org_atraso_m2)                    AS con_atraso
FROM disc_model_owner.b46029_po_flg_rcc

-- SELECT 'b46029_po_flg_maestras', count(*), count(DISTINCT codmes), min(codmes), max(codmes),
--        count(DISTINCT tip_doc || '|' || key_value), sum(flg_giro), sum(flg_edad_rl)
-- FROM disc_model_owner.b46029_po_flg_maestras

-- SELECT 'b46029_po_flg_clean', count(*), count(DISTINCT codmes), min(codmes), max(codmes),
--        count(DISTINCT tip_doc || '|' || key_value), sum(flg_clean), count(*) - sum(flg_clean)
-- FROM disc_model_owner.b46029_po_flg_clean

-- SELECT 'b46029_po_scoring_v1v2', count(*), count(DISTINCT p_codmes), min(p_codmes), max(p_codmes),
--        count(DISTINCT tip_doc || '|' || key_value),
--        count_if(prob_modelo_cal_v1 IS NULL), count_if(prob_modelo_cal_v2 IS NULL)
-- FROM disc_model_owner.b46029_po_scoring_v1v2
