-- v_20g_mad.sql | READ-ONLY | valida disc_model_owner.ds_adm_bpe_bankbn_mad (etapa 20g)
--  1. UN SOLO STATEMENT, sin punto y coma, ASCII puro. No crea ni escribe nada.
--  2. Devuelve UNA fila de agregados. No proyecta key_value ni ninguna clave a nivel detalle.
--  3. Grano declarado en 2t*_m_mad.sql: (codmes, tip_doc, key_value).
--  4. mad ACUMULA los 7 tramos (CREATE en 2t1_m, INSERT INTO en 2t2..2t7). falla_meses_incompleto
--     solo es exigible DESPUES del ultimo tramo. falla_gap_meses aplica en cualquier momento.
--  5. b.probabilidad presente: n_con_score = COUNT(probabilidad). Si es 0 el LEFT JOIN al score
--     no pego nunca (o la columna quedo fuera de la proyeccion) y 40_cal marcaria todo flg_clean=98.
--     n_sin_score > 0 es legitimo y por eso NO es una falla_.
--  6. Q1: target_12m usa ventanas de 12m. Como las de 12m contienen a las de 6m, target_12m >= target_06m.
--     falla_q1_target_monot detecta la inversion. falla_q1_12m_igual_6m detecta el bug viejo
--     (si target_12m nunca difiere de target_06m, las ventanas son la misma).
--  7. A7: n_con_m2 cuenta filas con algun *_m2 poblado. 0 => el bloque m0-2 no viajo y 40_cal
--     no tendria insumo para los filtros de CASO2.
--  8. Duplicados al grano: GROUP BY + HAVING COUNT(*)>1. falla_score_dup es la marca que el propio
--     CTAS deja cuando el score duplica la llave.
--  9. Todas las columnas falla_* valen 0 si la etapa esta sana.
WITH par AS (
    SELECT '202206' AS mes_ini, '202506' AS mes_fin, 37 AS n_meses_esp
),
base AS (
    SELECT
        CAST(t.codmes            AS VARCHAR) AS codmes,
        CAST(t.p_codmes          AS VARCHAR) AS p_codmes,
        CAST(t.tip_doc           AS VARCHAR) AS tip_doc,
        CAST(t.key_value         AS VARCHAR) AS key_value,
        CAST(t.ent_alta          AS VARCHAR) AS ent_alta,
        CAST(t.flag_bpe_parcial  AS VARCHAR) AS flag_bpe_parcial,
        CAST(t.segmento_reactiva AS VARCHAR) AS segmento_reactiva,
        CAST(t.flag_malo_12m     AS VARCHAR) AS flag_malo_12m,
        CAST(t.clasificacion_m2  AS VARCHAR) AS clasificacion_m2,
        t.probabilidad,
        t.target_06m,
        t.target_09m,
        t.target_12m,
        t.saldo_vig_m2,
        t.saldo_cast_m2,
        t.saldo_jud_m2,
        t.saldo_ref_m2,
        t.saldo_rest_m2,
        t.dm_org_m2,
        t.saldo_novig_neg_12um_v2,
        t.sld_castigado_12um_rl_v2,
        t.falla_sin_score,
        t.falla_score_dup,
        t.falla_pd_rango,
        t.falla_sin_entidad_alta,
        t.falla_madurez_12m,
        t.falla_target_nulo,
        TRY_CAST(SUBSTR(CAST(t.codmes AS VARCHAR), 1, 4) AS INTEGER) * 12
            + TRY_CAST(SUBSTR(CAST(t.codmes AS VARCHAR), 5, 2) AS INTEGER) AS mes_idx,
        p.mes_ini,
        p.mes_fin,
        p.n_meses_esp
    FROM disc_model_owner.ds_adm_bpe_bankbn_mad t
    CROSS JOIN par p
),
agg AS (
    SELECT
        COUNT(*)               AS n_filas,
        COUNT(DISTINCT codmes) AS n_meses,
        MIN(codmes)            AS mes_min,
        MAX(codmes)            AS mes_max,
        MIN(mes_idx)           AS idx_min,
        MAX(mes_idx)           AS idx_max,
        COUNT(probabilidad)    AS n_con_score,
        SUM(CASE WHEN COALESCE(falla_sin_score, 0) = 1 THEN 1 ELSE 0 END)  AS n_sin_score,
        SUM(CASE WHEN target_12m = 1 THEN 1 ELSE 0 END)                    AS n_target12_malo,
        SUM(CASE WHEN target_12m <> target_06m THEN 1 ELSE 0 END)          AS n_target12_dif_06m,
        SUM(CASE WHEN COALESCE(saldo_vig_m2, 0) <> 0
                   OR clasificacion_m2 IS NOT NULL
                   OR saldo_cast_m2    IS NOT NULL
                   OR saldo_jud_m2     IS NOT NULL
                   OR saldo_ref_m2     IS NOT NULL
                   OR saldo_rest_m2    IS NOT NULL
                   OR COALESCE(dm_org_m2, 0) <> 0
                 THEN 1 ELSE 0 END)                                        AS n_con_m2,
        SUM(CASE WHEN saldo_novig_neg_12um_v2 IS NOT NULL
                   OR sld_castigado_12um_rl_v2 IS NOT NULL
                 THEN 1 ELSE 0 END)                                        AS n_con_q5_v2,
        SUM(CASE WHEN codmes IS NULL OR tip_doc IS NULL OR key_value IS NULL
                 THEN 1 ELSE 0 END)                                        AS c_key_null,
        SUM(CASE WHEN codmes IS NULL OR NOT REGEXP_LIKE(codmes, '^[0-9]{6}$')
                 THEN 1 ELSE 0 END)                                        AS c_codmes_fmt,
        SUM(CASE WHEN codmes < mes_ini OR codmes > mes_fin THEN 1 ELSE 0 END) AS c_rango,
        SUM(CASE WHEN p_codmes IS DISTINCT FROM codmes THEN 1 ELSE 0 END)  AS c_pcodmes,
        SUM(CASE WHEN COALESCE(falla_score_dup, 0) = 1 THEN 1 ELSE 0 END)  AS c_score_dup,
        SUM(CASE WHEN COALESCE(falla_pd_rango, 0) = 1 THEN 1 ELSE 0 END)   AS c_pd_rango,
        SUM(CASE WHEN COALESCE(falla_sin_entidad_alta, 0) = 1 THEN 1 ELSE 0 END) AS c_sin_ent_alta,
        SUM(CASE WHEN COALESCE(falla_madurez_12m, 0) = 1 THEN 1 ELSE 0 END) AS c_madurez,
        SUM(CASE WHEN COALESCE(falla_target_nulo, 0) = 1 THEN 1 ELSE 0 END) AS c_target_nulo,
        SUM(CASE WHEN target_06m IS NULL OR target_06m NOT IN (0, 1)
                   OR target_09m IS NULL OR target_09m NOT IN (0, 1)
                   OR target_12m IS NULL OR target_12m NOT IN (0, 1)
                 THEN 1 ELSE 0 END)                                        AS c_target_dom,
        SUM(CASE WHEN COALESCE(target_06m, 0) > COALESCE(target_09m, 0)
                   OR COALESCE(target_09m, 0) > COALESCE(target_12m, 0)
                 THEN 1 ELSE 0 END)                                        AS c_target_monot,
        SUM(CASE WHEN flag_bpe_parcial IS NULL THEN 1 ELSE 0 END)          AS c_bpe_nulo,
        SUM(CASE WHEN COALESCE(flag_bpe_parcial, '99. Sin Caida') NOT IN (
                        '01. Titular con Saldo Comercial No Vigente RCC (Ultimo mes)',
                        '02. Titular con Saldo Comercial No Vigente RCC (Ultimos 12 meses)',
                        '03. Titular con Calificacion SBS diferente a 100% Normal',
                        '09. RRLL con Saldo RCC en Castigo (Ultimos 12 meses)',
                        '17. Titular >= 75 o < 25 anos',
                        '18. RRLL >= 75 o < 25 anos',
                        '19. PNSN',
                        '20. Estado Diferente A',
                        '22. Giro Restringido',
                        '23. Ubigeo Restringido',
                        '99. Sin Caida')
                 THEN 1 ELSE 0 END)                                        AS c_bpe_dom,
        SUM(CASE WHEN COALESCE(segmento_reactiva, '') NOT IN ('SOLO NEGOCIO', 'MIXTO',
                                                              'REACTIVA', 'SIN DEUDA')
                 THEN 1 ELSE 0 END)                                        AS c_segmento_dom,
        SUM(CASE WHEN COALESCE(flag_malo_12m, '') NOT IN (
                        'CASTIGADO_ORIGEN', 'JUDICIAL_ORIGEN', 'REESTRUCTURADO_ORIGEN',
                        'REFINANCIADO_ORIGEN', 'CLASIF_NO_NORMAL', 'NO_BPE',
                        'CON_DIASATRASO_ORIGEN', 'ESPECIALES', 'SIN_INFORMACION',
                        'INSUFICIENTE', 'MALO', 'INDETERMINADO', 'BUENO')
                 THEN 1 ELSE 0 END)                                        AS c_flag_malo_dom
    FROM base
),
dup AS (
    SELECT
        COUNT(*)             AS n_grano_dup,
        COALESCE(SUM(n), 0)  AS n_filas_en_dup
    FROM (
        SELECT COUNT(*) AS n
        FROM base
        GROUP BY codmes, tip_doc, key_value
        HAVING COUNT(*) > 1
    ) d
),
cli AS (
    SELECT COUNT(*) AS n_clientes
    FROM (
        SELECT tip_doc, key_value
        FROM base
        GROUP BY tip_doc, key_value
    ) c
),
mes AS (
    SELECT
        MIN(n) AS n_filas_mes_min,
        MAX(n) AS n_filas_mes_max
    FROM (
        SELECT codmes, COUNT(*) AS n
        FROM base
        GROUP BY codmes
    ) m
)
SELECT
    a.n_filas,
    c.n_clientes,
    a.n_meses,
    a.mes_min,
    a.mes_max,
    a.n_con_score,
    a.n_sin_score,
    a.n_target12_malo,
    a.n_target12_dif_06m,
    a.n_con_m2,
    a.n_con_q5_v2,
    m.n_filas_mes_min,
    m.n_filas_mes_max,
    d.n_grano_dup,
    d.n_filas_en_dup,
    CASE WHEN a.n_filas = 0                          THEN 1 ELSE 0 END AS falla_sin_filas,
    CASE WHEN d.n_grano_dup > 0                      THEN 1 ELSE 0 END AS falla_dup_grano,
    CASE WHEN c.n_clientes = 0                       THEN 1 ELSE 0 END AS falla_sin_clientes,
    CASE WHEN a.c_key_null > 0                       THEN 1 ELSE 0 END AS falla_key_null,
    CASE WHEN a.c_codmes_fmt > 0                     THEN 1 ELSE 0 END AS falla_codmes_fmt,
    CASE WHEN a.c_rango > 0                          THEN 1 ELSE 0 END AS falla_rango_codmes,
    CASE WHEN a.idx_max - a.idx_min + 1 <> a.n_meses THEN 1 ELSE 0 END AS falla_gap_meses,
    CASE WHEN a.n_meses <> p.n_meses_esp             THEN 1 ELSE 0 END AS falla_meses_incompleto,
    CASE WHEN a.c_pcodmes > 0                        THEN 1 ELSE 0 END AS falla_pcodmes,
    CASE WHEN a.n_con_score = 0                      THEN 1 ELSE 0 END AS falla_probabilidad_ausente,
    CASE WHEN a.c_score_dup > 0                      THEN 1 ELSE 0 END AS falla_score_dup,
    CASE WHEN a.c_pd_rango > 0                       THEN 1 ELSE 0 END AS falla_pd_rango,
    CASE WHEN a.c_sin_ent_alta > 0                   THEN 1 ELSE 0 END AS falla_sin_ent_alta,
    CASE WHEN a.c_madurez > 0                        THEN 1 ELSE 0 END AS falla_madurez_12m,
    CASE WHEN a.c_target_nulo > 0                    THEN 1 ELSE 0 END AS falla_target_nulo,
    CASE WHEN a.c_target_dom > 0                     THEN 1 ELSE 0 END AS falla_target_dominio,
    CASE WHEN a.c_target_monot > 0                   THEN 1 ELSE 0 END AS falla_q1_target_monot,
    CASE WHEN a.n_target12_dif_06m = 0               THEN 1 ELSE 0 END AS falla_q1_12m_igual_6m,
    CASE WHEN a.n_con_m2 = 0                         THEN 1 ELSE 0 END AS falla_a7_m2_vacio,
    CASE WHEN a.n_con_q5_v2 = 0                      THEN 1 ELSE 0 END AS falla_q5_v2_vacio,
    CASE WHEN a.c_bpe_nulo > 0                       THEN 1 ELSE 0 END AS falla_bpe_parcial_nulo,
    CASE WHEN a.c_bpe_dom > 0                        THEN 1 ELSE 0 END AS falla_bpe_parcial_dom,
    CASE WHEN a.c_segmento_dom > 0                   THEN 1 ELSE 0 END AS falla_segmento_dom,
    CASE WHEN a.c_flag_malo_dom > 0                  THEN 1 ELSE 0 END AS falla_flag_malo_dom
FROM agg a
CROSS JOIN dup d
CROSS JOIN cli c
CROSS JOIN mes m
CROSS JOIN par p
