-- =====================================================================================
-- QA_scoring_po.sql | control de la tabla final b46029_po_scoring_v1v2
--
-- Correr DESPUES de PO_4. Una sola pasada de agregacion sobre la tabla, despivotada
-- con UNNEST de arrays paralelos (no ARRAY(ROW): Athena no lo expande en columnas).
--
-- CRITERIOS DE APROBACION — la columna `criterio` los lleva escritos
--   Los que DEBEN dar 0:
--     nulos en cualquiera de los 6 campos de salida
--     flg_clean fuera de {0,1}
--     ft provisional
--     V1 != V2 donde flg_clean = 1      <- si difieren, el enrutamiento esta roto
--     V2 == V1 donde flg_clean = 0      <- si coinciden, la cadena dirty no se aplico
--
--   Los informativos: conteos, rangos y distribucion de grupos.
--
-- Las dos comparaciones V1/V2 son el control interno mas fuerte que hay aqui:
-- donde flg_clean=1 la cadena V2 ES la clean, o sea V1, y tienen que salir identicas
-- bit a bit. Donde flg_clean=0 tienen que diferir, porque se aplica la dirty.
--
-- READ-ONLY.
-- =====================================================================================

WITH a AS (
  SELECT
    cast(count(*) AS bigint)                                              AS n_filas,
    cast(count(DISTINCT p_codmes) AS bigint)                              AS n_meses,
    cast(min(cast(p_codmes AS int)) AS bigint)                            AS mes_min,
    cast(max(cast(p_codmes AS int)) AS bigint)                            AS mes_max,
    cast(count(DISTINCT tip_doc || '|' || key_value) AS bigint)           AS n_clientes,

    cast(count_if(prob_modelo_cal_v1 IS NULL) AS bigint)                  AS nul_pd_v1,
    cast(count_if(prob_modelo_cal_v2 IS NULL) AS bigint)                  AS nul_pd_v2,
    cast(count_if(puntuacion_cal_v1 IS NULL) AS bigint)                   AS nul_pt_v1,
    cast(count_if(puntuacion_cal_v2 IS NULL) AS bigint)                   AS nul_pt_v2,
    cast(count_if(grupos_cal_v1 IS NULL) AS bigint)                       AS nul_gr_v1,
    cast(count_if(grupos_cal_v2 IS NULL) AS bigint)                       AS nul_gr_v2,
    cast(count_if(flg_clean NOT IN (0,1) OR flg_clean IS NULL) AS bigint) AS flg_malo,
    cast(count_if(ft_meses_usados < 3) AS bigint)                         AS ft_prov,

    cast(count_if(flg_clean = 1) AS bigint)                               AS n_clean,
    cast(count_if(flg_clean = 0) AS bigint)                               AS n_dirty,
    cast(count_if(flg_impulsa_bwd = 1) AS bigint)                         AS n_impulsa,
    cast(count_if(flg_reactiva_puro = 1) AS bigint)                       AS n_reactiva,

    -- controles internos: V1 y V2 deben coincidir en clean y diferir en dirty
    cast(count_if(flg_clean = 1 AND abs(prob_modelo_cal_v1 - prob_modelo_cal_v2) > 1e-12) AS bigint) AS c_clean_difieren,
    cast(count_if(flg_clean = 0 AND abs(prob_modelo_cal_v1 - prob_modelo_cal_v2) <= 1e-12) AS bigint) AS c_dirty_iguales,

    cast(round(10000 * min(prob_modelo_cal_v1)) AS bigint)                AS pd1_min_bp,
    cast(round(10000 * max(prob_modelo_cal_v1)) AS bigint)                AS pd1_max_bp,
    cast(round(10000 * avg(prob_modelo_cal_v1)) AS bigint)                AS pd1_avg_bp,
    cast(round(10000 * avg(prob_modelo_cal_v2)) AS bigint)                AS pd2_avg_bp,

    cast(count_if(grupos_cal_v1 = 'G1') AS bigint)                        AS v1_g1,
    cast(count_if(grupos_cal_v1 = 'G2') AS bigint)                        AS v1_g2,
    cast(count_if(grupos_cal_v1 = 'G3') AS bigint)                        AS v1_g3,
    cast(count_if(grupos_cal_v1 = 'G4') AS bigint)                        AS v1_g4,
    cast(count_if(grupos_cal_v1 = 'G5') AS bigint)                        AS v1_g5,
    cast(count_if(grupos_cal_v2 = 'G1') AS bigint)                        AS v2_g1,
    cast(count_if(grupos_cal_v2 = 'G2') AS bigint)                        AS v2_g2,
    cast(count_if(grupos_cal_v2 = 'G3') AS bigint)                        AS v2_g3,
    cast(count_if(grupos_cal_v2 = 'G4') AS bigint)                        AS v2_g4,
    cast(count_if(grupos_cal_v2 = 'G5') AS bigint)                        AS v2_g5
  FROM disc_model_owner.b46029_po_scoring_v1v2
)

SELECT x.chequeo, x.valor, x.criterio
FROM a
CROSS JOIN UNNEST(
  ARRAY[
    '01 filas totales',
    '02 meses distintos',
    '03 p_codmes minimo',
    '04 p_codmes maximo',
    '05 clientes distintos',
    '06 NULOS prob_modelo_cal_v1',
    '07 NULOS prob_modelo_cal_v2',
    '08 NULOS puntuacion_cal_v1',
    '09 NULOS puntuacion_cal_v2',
    '10 NULOS grupos_cal_v1',
    '11 NULOS grupos_cal_v2',
    '12 flg_clean fuera de 0/1',
    '13 f_t PROVISIONAL',
    '14 flg_clean = 1',
    '15 flg_clean = 0',
    '16 con flg_impulsa_bwd',
    '17 con flg_reactiva_puro',
    '18 CLEAN donde V1 != V2',
    '19 DIRTY donde V1 == V2',
    '20 pd_v1 minimo (pb)',
    '21 pd_v1 maximo (pb)',
    '22 pd_v1 promedio (pb)',
    '23 pd_v2 promedio (pb)',
    '24 V1 grupo G1', '25 V1 grupo G2', '26 V1 grupo G3', '27 V1 grupo G4', '28 V1 grupo G5',
    '29 V2 grupo G1', '30 V2 grupo G2', '31 V2 grupo G3', '32 V2 grupo G4', '33 V2 grupo G5'
  ],
  ARRAY[n_filas, n_meses, mes_min, mes_max, n_clientes,
        nul_pd_v1, nul_pd_v2, nul_pt_v1, nul_pt_v2, nul_gr_v1, nul_gr_v2,
        flg_malo, ft_prov, n_clean, n_dirty, n_impulsa, n_reactiva,
        c_clean_difieren, c_dirty_iguales,
        pd1_min_bp, pd1_max_bp, pd1_avg_bp, pd2_avg_bp,
        v1_g1, v1_g2, v1_g3, v1_g4, v1_g5,
        v2_g1, v2_g2, v2_g3, v2_g4, v2_g5],
  ARRAY['informativo','DEBE ser 30','informativo','informativo','informativo',
        'DEBE ser 0','DEBE ser 0','DEBE ser 0','DEBE ser 0','DEBE ser 0','DEBE ser 0',
        'DEBE ser 0','DEBE ser 0','informativo','informativo','informativo','informativo',
        'DEBE ser 0 — si no, el enrutamiento esta roto',
        'DEBE ser 0 — si no, la cadena dirty no se aplico',
        'informativo','informativo','informativo','informativo',
        'informativo','informativo','informativo','informativo','informativo',
        'informativo','informativo','informativo','informativo','informativo']
) AS x(chequeo, valor, criterio)
ORDER BY x.chequeo
