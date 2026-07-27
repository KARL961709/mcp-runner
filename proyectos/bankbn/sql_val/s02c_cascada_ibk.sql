-- s02c_cascada_ibk.sql | cascada con el dirty colgando de IBK: Total -> SSFF/IBK, y dentro de IBK clean PPNN/PPJJ + dirty
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
    SELECT count(1)                                                                    AS n_tot,
           sum(CASE WHEN ssff = 1 THEN 1 ELSE 0 END)                                   AS n_ssff,
           sum(CASE WHEN ibk  = 1 THEN 1 ELSE 0 END)                                   AS n_ibk,
           sum(CASE WHEN ibk = 1 AND flg_clean = 0 THEN 1 ELSE 0 END)                  AS n_ibk_dirty,
           sum(CASE WHEN ibk = 1 AND flg_clean = 1 AND ppjj = 0 THEN 1 ELSE 0 END)     AS n_d1,
           sum(CASE WHEN ibk = 1 AND flg_clean = 1 AND ppjj = 1 THEN 1 ELSE 0 END)     AS n_d2,
           sum(tgt)                                                                    AS m_tot,
           sum(CASE WHEN ssff = 1 THEN tgt ELSE 0 END)                                 AS m_ssff,
           sum(CASE WHEN ibk  = 1 THEN tgt ELSE 0 END)                                 AS m_ibk,
           sum(CASE WHEN ibk = 1 AND flg_clean = 0 THEN tgt ELSE 0 END)                AS m_ibk_dirty,
           sum(CASE WHEN ibk = 1 AND flg_clean = 1 AND ppjj = 0 THEN tgt ELSE 0 END)   AS m_d1,
           sum(CASE WHEN ibk = 1 AND flg_clean = 1 AND ppjj = 1 THEN tgt ELSE 0 END)   AS m_d2
    FROM (
        SELECT flg_clean,
               CASE WHEN entidad IN ('BCP','BBVA','SCOTIA') THEN 1 ELSE 0 END AS ssff,
               CASE WHEN entidad = 'IBK' THEN 1 ELSE 0 END                    AS ibk,
               COALESCE(flg_ppjj, 0)                                          AS ppjj,
               CAST(target_12m AS BIGINT)                                     AS tgt
        FROM disc_model_owner.ds_adm_bpe_bankbn_cal
        WHERE CAST(codmes AS VARCHAR) IN ('202504','202505','202506')
          AND flg_clean IN (0, 1)
          AND target_12m IS NOT NULL
    ) z
) a
CROSS JOIN UNNEST(
    ARRAY[1, 2, 3, 4, 5, 6],
    ARRAY['1_TOTAL', '2_SSFF', '3_IBK', '4_IBK_DIRTY', '5_IBK_CLEAN_PPNN', '6_IBK_CLEAN_PPJJ'],
    ARRAY[a.n_tot, a.n_ssff, a.n_ibk, a.n_ibk_dirty, a.n_d1, a.n_d2],
    ARRAY[a.m_tot, a.m_ssff, a.m_ibk, a.m_ibk_dirty, a.m_d1, a.m_d2],
    ARRAY[a.n_tot, a.n_tot, a.n_tot, a.n_ibk, a.n_ibk, a.n_ibk],
    ARRAY['-', 'del total', 'del total', 'de IBK', 'de IBK', 'de IBK']
) AS t (orden, nivel, n, malos, base, etiqueta_base)
ORDER BY t.orden
