-- d2_evolutivo_rd_volumen.sql | evolutivo mensual: volumen y RD de clean y dirty, IBK con SSFF de referencia. 89 meses con target 12m maduro
SELECT CAST(codmes AS VARCHAR)                                                        AS codmes,
       sum(ibk)                                                                       AS n_ibk,
       sum(CASE WHEN ibk = 1 AND flg_clean = 1 THEN 1 ELSE 0 END)                     AS n_ibk_clean,
       sum(CASE WHEN ibk = 1 AND flg_clean = 0 THEN 1 ELSE 0 END)                     AS n_ibk_dirty,
       round(100.0 * sum(CASE WHEN ibk = 1 AND flg_clean = 0 THEN 1 ELSE 0 END)
                   / nullif(sum(ibk), 0), 2)                                          AS pct_dirty_ibk,
       round(100.0 * sum(CASE WHEN ibk = 1 AND flg_clean = 1 THEN tgt ELSE 0 END)
                   / nullif(sum(CASE WHEN ibk = 1 AND flg_clean = 1 THEN 1 ELSE 0 END), 0), 2) AS rd_ibk_clean,
       round(100.0 * sum(CASE WHEN ibk = 1 AND flg_clean = 0 THEN tgt ELSE 0 END)
                   / nullif(sum(CASE WHEN ibk = 1 AND flg_clean = 0 THEN 1 ELSE 0 END), 0), 2) AS rd_ibk_dirty,
       sum(1 - ibk)                                                                   AS n_ssff,
       round(100.0 * sum(CASE WHEN ibk = 0 AND flg_clean = 1 THEN tgt ELSE 0 END)
                   / nullif(sum(CASE WHEN ibk = 0 AND flg_clean = 1 THEN 1 ELSE 0 END), 0), 2) AS rd_ssff_clean,
       round(100.0 * sum(CASE WHEN ibk = 0 AND flg_clean = 0 THEN tgt ELSE 0 END)
                   / nullif(sum(CASE WHEN ibk = 0 AND flg_clean = 0 THEN 1 ELSE 0 END), 0), 2) AS rd_ssff_dirty,
       sum(CASE WHEN ibk = 1 AND flg_clean = 1 THEN tgt ELSE 0 END)                   AS malos_ibk_clean,
       sum(CASE WHEN ibk = 1 AND flg_clean = 0 THEN tgt ELSE 0 END)                   AS malos_ibk_dirty
FROM (
    SELECT codmes,
           CASE WHEN entidad = 'IBK' THEN 1 ELSE 0 END AS ibk,
           flg_clean,
           CAST(target_12m AS BIGINT)                  AS tgt
    FROM disc_model_owner.ds_adm_bpe_bankbn_cal
    WHERE CAST(codmes AS VARCHAR) BETWEEN '201802' AND '202506'
      AND flg_clean IN (0, 1)
      AND target_12m IS NOT NULL
) z
GROUP BY CAST(codmes AS VARCHAR)
ORDER BY codmes
