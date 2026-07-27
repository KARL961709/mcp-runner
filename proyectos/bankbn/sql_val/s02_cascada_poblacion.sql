-- s02_cascada_poblacion.sql | cascada del slide ETAPA 02 sobre los 3 ultimos meses cerrados rd12 (202504-202506)
SELECT t.orden,
       t.nivel,
       t.n                                                        AS n_3meses,
       round(t.n / 3.0, 0)                                        AS clientes_mes,
       t.malos                                                    AS malos_3meses,
       round(t.malos / 3.0, 0)                                    AS malos_mes,
       round(100.0 * t.malos / nullif(t.n, 0), 2)                 AS tasa_pct,
       round(100.0 * t.n / nullif(t.base, 0), 1)                  AS pct_sobre_base,
       t.etiqueta_base
FROM (
    SELECT count(1)                                                                        AS n_tot,
           sum(CASE WHEN flg_clean = 0 THEN 1 ELSE 0 END)                                  AS n_dirty,
           sum(CASE WHEN flg_clean = 1 AND entidad IN ('BCP','BBVA','SCOTIA') THEN 1 ELSE 0 END) AS n_a,
           sum(CASE WHEN flg_clean = 1 AND entidad = 'IBK' THEN 1 ELSE 0 END)              AS n_b,
           sum(CASE WHEN flg_clean = 1 AND entidad = 'IBK' AND ppjj = 0 THEN 1 ELSE 0 END) AS n_d1,
           sum(CASE WHEN flg_clean = 1 AND entidad = 'IBK' AND ppjj = 1 THEN 1 ELSE 0 END) AS n_d2,
           sum(tgt)                                                                        AS m_tot,
           sum(CASE WHEN flg_clean = 0 THEN tgt ELSE 0 END)                                AS m_dirty,
           sum(CASE WHEN flg_clean = 1 AND entidad IN ('BCP','BBVA','SCOTIA') THEN tgt ELSE 0 END) AS m_a,
           sum(CASE WHEN flg_clean = 1 AND entidad = 'IBK' THEN tgt ELSE 0 END)            AS m_b,
           sum(CASE WHEN flg_clean = 1 AND entidad = 'IBK' AND ppjj = 0 THEN tgt ELSE 0 END) AS m_d1,
           sum(CASE WHEN flg_clean = 1 AND entidad = 'IBK' AND ppjj = 1 THEN tgt ELSE 0 END) AS m_d2
    FROM (
        SELECT flg_clean, entidad,
               COALESCE(flg_ppjj, 0) AS ppjj,
               CAST(target_12m AS BIGINT) AS tgt
        FROM disc_model_owner.ds_adm_bpe_bankbn_cal
        WHERE CAST(codmes AS VARCHAR) IN ('202504','202505','202506')
          AND flg_clean IN (0, 1)
          AND target_12m IS NOT NULL
    ) z
) a
CROSS JOIN UNNEST(
    ARRAY[1, 2, 3, 4, 5, 6],
    ARRAY['1_TOTAL', '2_LIBERADO_DIRTY', '3_GRUPO_A_SSFF', '4_GRUPO_B_IBK', '5_DRIVER1_PPNN', '6_DRIVER2_PPJJ'],
    ARRAY[a.n_tot, a.n_dirty, a.n_a, a.n_b, a.n_d1, a.n_d2],
    ARRAY[a.m_tot, a.m_dirty, a.m_a, a.m_b, a.m_d1, a.m_d2],
    ARRAY[a.n_tot, a.n_tot, a.n_tot, a.n_tot, a.n_b, a.n_b],
    ARRAY['-', 'del total', 'del total', 'del total', 'del Grupo B', 'del Grupo B']
) AS t (orden, nivel, n, malos, base, etiqueta_base)
ORDER BY t.orden
