-- qa_02_ventana_grano.sql | ventana real, grano y cardinalidad de las 4 tablas finales mas los 12 tramos: dice que build corrio, si hay huecos de mes, fan-out o union rancia
WITH u AS (
    SELECT 1 AS ord, 'A1_po' AS tabla, CAST(count(1) AS BIGINT) AS n_filas,
           CAST(count(DISTINCT CAST(codmes AS VARCHAR) || '#' || CAST(tip_doc AS VARCHAR) || '#' || CAST(key_value AS VARCHAR)) AS BIGINT) AS n_granos,
           CAST(count(DISTINCT CAST(codmes AS VARCHAR)) AS BIGINT) AS n_meses,
           min(CAST(codmes AS VARCHAR)) AS mes_min, max(CAST(codmes AS VARCHAR)) AS mes_max
    FROM disc_model_owner.ds_adm_bpe_bankbn_po
    UNION ALL
    SELECT 2, 'A2_mad', CAST(count(1) AS BIGINT),
           CAST(count(DISTINCT CAST(codmes AS VARCHAR) || '#' || CAST(tip_doc AS VARCHAR) || '#' || CAST(key_value AS VARCHAR)) AS BIGINT),
           CAST(count(DISTINCT CAST(codmes AS VARCHAR)) AS BIGINT),
           min(CAST(codmes AS VARCHAR)), max(CAST(codmes AS VARCHAR))
    FROM disc_model_owner.ds_adm_bpe_bankbn_mad
    UNION ALL
    SELECT 3, 'A3_drivers', CAST(count(1) AS BIGINT),
           CAST(count(DISTINCT CAST(codmes AS VARCHAR) || '#' || CAST(tip_doc AS VARCHAR) || '#' || CAST(key_value AS VARCHAR)) AS BIGINT),
           CAST(count(DISTINCT CAST(codmes AS VARCHAR)) AS BIGINT),
           min(CAST(codmes AS VARCHAR)), max(CAST(codmes AS VARCHAR))
    FROM disc_model_owner.ds_adm_bpe_bankbn_drivers
    UNION ALL
    SELECT 4, 'A4_cal', CAST(count(1) AS BIGINT),
           CAST(count(DISTINCT CAST(codmes AS VARCHAR) || '#' || CAST(tip_doc AS VARCHAR) || '#' || CAST(key_value AS VARCHAR)) AS BIGINT),
           CAST(count(DISTINCT CAST(codmes AS VARCHAR)) AS BIGINT),
           min(CAST(codmes AS VARCHAR)), max(CAST(codmes AS VARCHAR))
    FROM disc_model_owner.ds_adm_bpe_bankbn_cal
    UNION ALL
    SELECT 11, 'B_po_t1', CAST(count(1) AS BIGINT), CAST(NULL AS BIGINT), CAST(count(DISTINCT CAST(codmes AS VARCHAR)) AS BIGINT), min(CAST(codmes AS VARCHAR)), max(CAST(codmes AS VARCHAR)) FROM disc_model_owner.ds_adm_bpe_bankbn_po_t1
    UNION ALL
    SELECT 12, 'B_po_t2', CAST(count(1) AS BIGINT), CAST(NULL AS BIGINT), CAST(count(DISTINCT CAST(codmes AS VARCHAR)) AS BIGINT), min(CAST(codmes AS VARCHAR)), max(CAST(codmes AS VARCHAR)) FROM disc_model_owner.ds_adm_bpe_bankbn_po_t2
    UNION ALL
    SELECT 13, 'B_po_t3', CAST(count(1) AS BIGINT), CAST(NULL AS BIGINT), CAST(count(DISTINCT CAST(codmes AS VARCHAR)) AS BIGINT), min(CAST(codmes AS VARCHAR)), max(CAST(codmes AS VARCHAR)) FROM disc_model_owner.ds_adm_bpe_bankbn_po_t3
    UNION ALL
    SELECT 14, 'B_po_t4', CAST(count(1) AS BIGINT), CAST(NULL AS BIGINT), CAST(count(DISTINCT CAST(codmes AS VARCHAR)) AS BIGINT), min(CAST(codmes AS VARCHAR)), max(CAST(codmes AS VARCHAR)) FROM disc_model_owner.ds_adm_bpe_bankbn_po_t4
    UNION ALL
    SELECT 15, 'B_po_t5', CAST(count(1) AS BIGINT), CAST(NULL AS BIGINT), CAST(count(DISTINCT CAST(codmes AS VARCHAR)) AS BIGINT), min(CAST(codmes AS VARCHAR)), max(CAST(codmes AS VARCHAR)) FROM disc_model_owner.ds_adm_bpe_bankbn_po_t5
    UNION ALL
    SELECT 16, 'B_po_t6', CAST(count(1) AS BIGINT), CAST(NULL AS BIGINT), CAST(count(DISTINCT CAST(codmes AS VARCHAR)) AS BIGINT), min(CAST(codmes AS VARCHAR)), max(CAST(codmes AS VARCHAR)) FROM disc_model_owner.ds_adm_bpe_bankbn_po_t6
    UNION ALL
    SELECT 21, 'C_mad_t1', CAST(count(1) AS BIGINT), CAST(NULL AS BIGINT), CAST(count(DISTINCT CAST(codmes AS VARCHAR)) AS BIGINT), min(CAST(codmes AS VARCHAR)), max(CAST(codmes AS VARCHAR)) FROM disc_model_owner.ds_adm_bpe_bankbn_mad_t1
    UNION ALL
    SELECT 22, 'C_mad_t2', CAST(count(1) AS BIGINT), CAST(NULL AS BIGINT), CAST(count(DISTINCT CAST(codmes AS VARCHAR)) AS BIGINT), min(CAST(codmes AS VARCHAR)), max(CAST(codmes AS VARCHAR)) FROM disc_model_owner.ds_adm_bpe_bankbn_mad_t2
    UNION ALL
    SELECT 23, 'C_mad_t3', CAST(count(1) AS BIGINT), CAST(NULL AS BIGINT), CAST(count(DISTINCT CAST(codmes AS VARCHAR)) AS BIGINT), min(CAST(codmes AS VARCHAR)), max(CAST(codmes AS VARCHAR)) FROM disc_model_owner.ds_adm_bpe_bankbn_mad_t3
    UNION ALL
    SELECT 24, 'C_mad_t4', CAST(count(1) AS BIGINT), CAST(NULL AS BIGINT), CAST(count(DISTINCT CAST(codmes AS VARCHAR)) AS BIGINT), min(CAST(codmes AS VARCHAR)), max(CAST(codmes AS VARCHAR)) FROM disc_model_owner.ds_adm_bpe_bankbn_mad_t4
    UNION ALL
    SELECT 25, 'C_mad_t5', CAST(count(1) AS BIGINT), CAST(NULL AS BIGINT), CAST(count(DISTINCT CAST(codmes AS VARCHAR)) AS BIGINT), min(CAST(codmes AS VARCHAR)), max(CAST(codmes AS VARCHAR)) FROM disc_model_owner.ds_adm_bpe_bankbn_mad_t5
    UNION ALL
    SELECT 26, 'C_mad_t6', CAST(count(1) AS BIGINT), CAST(NULL AS BIGINT), CAST(count(DISTINCT CAST(codmes AS VARCHAR)) AS BIGINT), min(CAST(codmes AS VARCHAR)), max(CAST(codmes AS VARCHAR)) FROM disc_model_owner.ds_adm_bpe_bankbn_mad_t6
),
d AS (
    SELECT ord, tabla, n_filas, n_granos, n_meses, mes_min, mes_max,
           CAST(date_diff('month', date_parse(mes_min, '%Y%m'), date_parse(mes_max, '%Y%m')) + 1 AS BIGINT) AS meses_span
    FROM u
)
SELECT ord, tabla, n_filas, n_granos,
       n_filas - n_granos AS filas_excedentes,
       n_meses, meses_span, meses_span - n_meses AS meses_faltantes,
       mes_min, mes_max,
       CAST(NULL AS BIGINT) AS delta_vs_union
FROM d
UNION ALL
SELECT 31, 'D_suma_po_t1a6',
       sum(CASE WHEN ord BETWEEN 11 AND 16 THEN n_filas ELSE 0 END),
       CAST(NULL AS BIGINT), CAST(NULL AS BIGINT),
       sum(CASE WHEN ord BETWEEN 11 AND 16 THEN n_meses ELSE 0 END),
       max(CASE WHEN ord = 1 THEN n_meses ELSE 0 END),
       sum(CASE WHEN ord BETWEEN 11 AND 16 THEN n_meses ELSE 0 END) - max(CASE WHEN ord = 1 THEN n_meses ELSE 0 END),
       min(CASE WHEN ord BETWEEN 11 AND 16 THEN mes_min END),
       max(CASE WHEN ord BETWEEN 11 AND 16 THEN mes_max END),
       sum(CASE WHEN ord BETWEEN 11 AND 16 THEN n_filas ELSE 0 END) - max(CASE WHEN ord = 1 THEN n_filas ELSE 0 END)
FROM d
UNION ALL
SELECT 32, 'D_suma_mad_t1a6',
       sum(CASE WHEN ord BETWEEN 21 AND 26 THEN n_filas ELSE 0 END),
       CAST(NULL AS BIGINT), CAST(NULL AS BIGINT),
       sum(CASE WHEN ord BETWEEN 21 AND 26 THEN n_meses ELSE 0 END),
       max(CASE WHEN ord = 2 THEN n_meses ELSE 0 END),
       sum(CASE WHEN ord BETWEEN 21 AND 26 THEN n_meses ELSE 0 END) - max(CASE WHEN ord = 2 THEN n_meses ELSE 0 END),
       min(CASE WHEN ord BETWEEN 21 AND 26 THEN mes_min END),
       max(CASE WHEN ord BETWEEN 21 AND 26 THEN mes_max END),
       sum(CASE WHEN ord BETWEEN 21 AND 26 THEN n_filas ELSE 0 END) - max(CASE WHEN ord = 2 THEN n_filas ELSE 0 END)
FROM d
ORDER BY 1
