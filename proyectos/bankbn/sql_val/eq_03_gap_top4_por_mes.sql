-- eq_03_gap_top4_por_mes.sql | el gap DENTRO del Top-4 mes a mes: A10 decia que era cero y ya no lo es
SELECT CAST(s.codmes AS VARCHAR)                                              AS codmes,
       CASE CAST(TRIM(CAST(s.cod_instit_financiera AS VARCHAR)) AS INT)
            WHEN 1 THEN 'BCP' WHEN 2 THEN 'IBK'
            WHEN 4 THEN 'SCOTIA' WHEN 6 THEN 'BBVA' END                       AS entidad,
       count(1)                                                               AS n_faltante,
       sum(CASE WHEN s.max_saldo > 0 THEN 1 ELSE 0 END)                       AS con_maxsaldo,
       sum(CASE WHEN s.saldo_m0 > 0 THEN 1 ELSE 0 END)                        AS con_saldo_m0,
       round(avg(TRY_CAST(s.max_saldo AS DOUBLE)), 0)                         AS max_saldo_prom,
       round(avg(TRY_CAST(s.saldo_m0 AS DOUBLE)), 0)                          AS saldo_m0_prom
FROM disc_riesgos.universo_bank_bpe_202301_202507_uni s
LEFT JOIN (
    SELECT CAST(codmes AS VARCHAR) AS cm, CAST(tip_doc AS VARCHAR) AS td, CAST(key_value AS VARCHAR) AS kv
    FROM disc_model_owner.ds_adm_bpe_bankbn_po
    WHERE CAST(codmes AS VARCHAR) BETWEEN '202301' AND '202507'
) n
  ON n.cm = CAST(s.codmes AS VARCHAR)
 AND n.td = CAST(s.tip_doc AS VARCHAR)
 AND n.kv = CAST(s.key_value AS VARCHAR)
WHERE n.kv IS NULL
  AND CAST(TRIM(CAST(s.cod_instit_financiera AS VARCHAR)) AS INT) IN (1,2,4,6)
GROUP BY CAST(s.codmes AS VARCHAR),
         CASE CAST(TRIM(CAST(s.cod_instit_financiera AS VARCHAR)) AS INT)
              WHEN 1 THEN 'BCP' WHEN 2 THEN 'IBK'
              WHEN 4 THEN 'SCOTIA' WHEN 6 THEN 'BBVA' END
ORDER BY codmes, entidad
