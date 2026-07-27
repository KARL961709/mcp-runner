-- eq_02_gap_caracterizacion.sql | quienes estan en el universo del desarrollador y no en el nuestro, por entidad y en los 31 meses
SELECT COALESCE(s.nombre_instit_financiera,'(SIN NOMBRE EN DIM)')            AS entidad,
       CAST(s.cod_instit_financiera AS VARCHAR)                              AS cod,
       CASE WHEN CAST(TRIM(CAST(s.cod_instit_financiera AS VARCHAR)) AS INT) IN (1,2,4,6)
            THEN 'TOP4' ELSE 'FUERA_TOP4' END                                AS grupo,
       count(1)                                                              AS n_faltante,
       count(DISTINCT CAST(s.codmes AS VARCHAR))                             AS n_meses,
       sum(CASE WHEN s.max_saldo > 0 THEN 1 ELSE 0 END)                      AS con_maxsaldo,
       sum(CASE WHEN s.saldo_m0 > 0 THEN 1 ELSE 0 END)                       AS con_saldo_m0
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
GROUP BY COALESCE(s.nombre_instit_financiera,'(SIN NOMBRE EN DIM)'),
         CAST(s.cod_instit_financiera AS VARCHAR),
         CASE WHEN CAST(TRIM(CAST(s.cod_instit_financiera AS VARCHAR)) AS INT) IN (1,2,4,6)
              THEN 'TOP4' ELSE 'FUERA_TOP4' END
ORDER BY n_faltante DESC
