-- QA3. CASCADA del slide sobre 202206-202506: Total / Grupo A SSFF / Grupo B IBK / PPNN / PPJJ / Liberado CASO1 / Dirty (read-only)
WITH par AS (
    SELECT '202206' AS mes_ini, '202506' AS mes_fin, '00002' AS ent_ibk
),
base AS (
    SELECT
        c.codmes,
        c.flg_clean,
        c.flg_ppjj,
        c.cod_instit_financiera,
        c.flag_bpe_parcial,
        c.target_12m,
        p.ent_ibk
    FROM disc_model_owner.ds_adm_bpe_bankbn_cal c
    CROSS JOIN par p
    WHERE c.codmes BETWEEN p.mes_ini AND p.mes_fin
      AND c.flg_clean IN (0, 1)
),
meses AS (
    SELECT CAST(COUNT(DISTINCT codmes) AS DOUBLE) AS n_meses
    FROM base
    WHERE flg_clean = 1
),
nodos AS (
    SELECT 1 AS orden, '1. Total' AS nodo, b.target_12m AS tgt
    FROM base b
    WHERE b.flg_clean = 1
    UNION ALL
    SELECT 2, '2. Grupo A - SSFF (BCP/BBVA/SCOTIA)', b.target_12m
    FROM base b
    WHERE b.flg_clean = 1
      AND COALESCE(b.cod_instit_financiera, '') <> b.ent_ibk
    UNION ALL
    SELECT 3, '3. Grupo B - IBK (00002)', b.target_12m
    FROM base b
    WHERE b.flg_clean = 1
      AND COALESCE(b.cod_instit_financiera, '') = b.ent_ibk
    UNION ALL
    SELECT 4, '4. Driver1 - PPNN', b.target_12m
    FROM base b
    WHERE b.flg_clean = 1
      AND COALESCE(b.flg_ppjj, 0) = 0
    UNION ALL
    SELECT 5, '5. Driver2 - PPJJ', b.target_12m
    FROM base b
    WHERE b.flg_clean = 1
      AND COALESCE(b.flg_ppjj, 0) = 1
    UNION ALL
    SELECT 6, '6. Liberado CASO1 (SUNAT estado/giro/ubigeo)', b.target_12m
    FROM base b
    WHERE b.flg_clean = 1
      AND COALESCE(b.flag_bpe_parcial, '') IN ('20. Estado Diferente A',
                                               '22. Giro Restringido',
                                               '23. Ubigeo Restringido')
    UNION ALL
    SELECT 7, '7. Dirty (flg_clean=0)', b.target_12m
    FROM base b
    WHERE b.flg_clean = 0
)
SELECT
    n.orden,
    n.nodo,
    m.n_meses,
    COUNT(*)                                                              AS clientes,
    CAST(COUNT(*) AS DOUBLE) / NULLIF(m.n_meses, 0)                       AS clientes_mes,
    SUM(CASE WHEN n.tgt = 1 THEN 1 ELSE 0 END)                            AS malos,
    CAST(SUM(CASE WHEN n.tgt = 1 THEN 1 ELSE 0 END) AS DOUBLE)
        / NULLIF(m.n_meses, 0)                                            AS malos_mes,
    CAST(SUM(CASE WHEN n.tgt = 1 THEN 1 ELSE 0 END) AS DOUBLE)
        / NULLIF(COUNT(*), 0)                                             AS tasa
FROM nodos n
CROSS JOIN meses m
GROUP BY n.orden, n.nodo, m.n_meses
ORDER BY n.orden
