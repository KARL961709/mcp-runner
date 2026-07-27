-- qa_01_censo_contrato.sql | metadata pura: que build quedo en disco, contrato de columnas y alineacion ordinal de los UNION ALL posicionales | costo cero, correr PRIMERO
WITH c AS (
    SELECT table_name, column_name, ordinal_position, data_type
    FROM information_schema.columns
    WHERE table_schema = 'disc_model_owner'
      AND table_name IN (
          'ds_adm_bpe_bankbn_po','ds_adm_bpe_bankbn_mad','ds_adm_bpe_bankbn_drivers','ds_adm_bpe_bankbn_cal',
          'ds_adm_bpe_bankbn_po_t1','ds_adm_bpe_bankbn_po_t2','ds_adm_bpe_bankbn_po_t3',
          'ds_adm_bpe_bankbn_po_t4','ds_adm_bpe_bankbn_po_t5','ds_adm_bpe_bankbn_po_t6',
          'ds_adm_bpe_bankbn_mad_t1','ds_adm_bpe_bankbn_mad_t2','ds_adm_bpe_bankbn_mad_t3',
          'ds_adm_bpe_bankbn_mad_t4','ds_adm_bpe_bankbn_mad_t5','ds_adm_bpe_bankbn_mad_t6')
),
t AS (
    SELECT
        table_name,
        CAST(count(1) AS BIGINT) AS n_col,
        CAST(sum(CASE WHEN column_name IN ('target_01m','target_02m','target_03m','target_04m','target_05m','target_06m','target_07m','target_08m','target_09m','target_10m','target_11m','target_12m') THEN 1 ELSE 0 END) AS BIGINT) AS n_targets,
        CAST(max(CASE WHEN column_name = 'rn' THEN 1 ELSE 0 END) AS BIGINT) AS f_rn,
        CAST(max(CASE WHEN column_name = 'rank' THEN 1 ELSE 0 END) AS BIGINT) AS f_rank_viejo,
        CAST(max(CASE WHEN column_name = 'marca_entidad' THEN 1 ELSE 0 END) AS BIGINT) AS f_marca_entidad,
        CAST(max(CASE WHEN column_name = 'score_p_codmes' THEN 1 ELSE 0 END) AS BIGINT) AS f_score_pcodmes,
        CAST(max(CASE WHEN column_name = 'flg_calib' THEN 1 ELSE 0 END) AS BIGINT) AS f_flg_calib,
        CAST(max(CASE WHEN column_name = 'entidad' THEN 1 ELSE 0 END) AS BIGINT) AS f_entidad
    FROM c
    GROUP BY table_name
),
fam AS (
    SELECT
        CASE WHEN table_name LIKE 'ds_adm_bpe_bankbn_po%' THEN 'PO' ELSE 'MAD' END AS familia,
        ordinal_position,
        CAST(count(DISTINCT table_name) AS BIGINT) AS n_tab,
        CAST(count(DISTINCT column_name) AS BIGINT) AS n_nom,
        CAST(count(DISTINCT data_type) AS BIGINT) AS n_tipo
    FROM c
    WHERE table_name LIKE 'ds_adm_bpe_bankbn_po%' OR table_name LIKE 'ds_adm_bpe_bankbn_mad%'
    GROUP BY 1, 2
)
SELECT
    'A_TABLA' AS bloque,
    table_name AS item,
    n_col,
    n_targets,
    f_rn,
    f_rank_viejo,
    f_marca_entidad,
    f_score_pcodmes,
    f_flg_calib,
    f_entidad,
    CAST(0 AS BIGINT) AS n_viol,
    'censo de columnas de la tabla' AS nota
FROM t
UNION ALL
SELECT
    'B_CONTRATO',
    'drivers menos mad',
    max(CASE WHEN table_name = 'ds_adm_bpe_bankbn_drivers' THEN n_col ELSE 0 END) - max(CASE WHEN table_name = 'ds_adm_bpe_bankbn_mad' THEN n_col ELSE 0 END),
    CAST(10 AS BIGINT),
    max(CASE WHEN table_name = 'ds_adm_bpe_bankbn_cal' THEN n_col ELSE 0 END),
    CAST(61 AS BIGINT),
    max(CASE WHEN table_name = 'ds_adm_bpe_bankbn_po' THEN n_col ELSE 0 END),
    CAST(45 AS BIGINT),
    max(CASE WHEN table_name = 'ds_adm_bpe_bankbn_cal' THEN n_targets ELSE 0 END),
    CAST(12 AS BIGINT),
    CASE WHEN max(CASE WHEN table_name = 'ds_adm_bpe_bankbn_drivers' THEN n_col ELSE 0 END) - max(CASE WHEN table_name = 'ds_adm_bpe_bankbn_mad' THEN n_col ELSE 0 END) <> 10 THEN 1 ELSE 0 END
    + CASE WHEN max(CASE WHEN table_name = 'ds_adm_bpe_bankbn_cal' THEN n_col ELSE 0 END) <> 61 THEN 1 ELSE 0 END
    + CASE WHEN max(CASE WHEN table_name = 'ds_adm_bpe_bankbn_po' THEN n_col ELSE 0 END) <> 45 THEN 1 ELSE 0 END
    + CASE WHEN max(CASE WHEN table_name = 'ds_adm_bpe_bankbn_cal' THEN n_targets ELSE 0 END) <> 12 THEN 1 ELSE 0 END,
    'pares medido-esperado: n_col=delta_drivers_mad vs n_targets=10, f_rn=cols_cal vs f_rank_viejo=61, f_marca_entidad=cols_po vs f_score_pcodmes=45, f_flg_calib=targets_cal vs f_entidad=12'
FROM t
UNION ALL
SELECT
    'C_ALINEACION',
    familia,
    CAST(count(1) AS BIGINT),
    CAST(max(n_tab) AS BIGINT),
    CAST(sum(CASE WHEN n_nom > 1 THEN 1 ELSE 0 END) AS BIGINT),
    CAST(sum(CASE WHEN n_tipo > 1 THEN 1 ELSE 0 END) AS BIGINT),
    CAST(sum(CASE WHEN n_tab < 7 THEN 1 ELSE 0 END) AS BIGINT),
    CAST(0 AS BIGINT),
    CAST(0 AS BIGINT),
    CAST(0 AS BIGINT),
    CAST(sum(CASE WHEN n_nom > 1 OR n_tipo > 1 OR n_tab < 7 THEN 1 ELSE 0 END) AS BIGINT),
    'n_col=posiciones_ordinales, n_targets=tablas_encontradas_esperado_7, f_rn=pos_nombre_discordante, f_rank_viejo=pos_tipo_discordante, f_marca_entidad=pos_tabla_faltante'
FROM fam
GROUP BY familia
ORDER BY 1, 2
