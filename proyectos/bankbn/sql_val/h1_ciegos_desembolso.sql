-- h1_ciegos_desembolso.sql | los ciegos del target nunca desembolsaron (72x) o desembolsaron y cancelaron? separa cero verdadero de no observable
SELECT c.entidad,
       CASE WHEN c.flg_clean = 1 THEN 'clean' ELSE 'dirty' END                        AS bucket,
       CASE WHEN d.dias_atraso_12m IS NULL THEN '1_ciego' ELSE '2_observado' END      AS estado,
       CASE WHEN r.n14 > 0 THEN 'con_desembolso_m0' ELSE 'solo_contingente_m0' END    AS origen,
       count(1)                                                                       AS n,
       sum(c.target_12m)                                                              AS malos,
       round(100.0 * sum(c.target_12m) / count(1), 2)                                 AS badrate_pct,
       round(avg(r.n14), 2)                                                           AS cuentas14_prom,
       round(avg(r.n72), 2)                                                           AS cuentas72_prom
FROM disc_model_owner.ds_adm_bpe_bankbn_cal c
INNER JOIN disc_model_owner.ds_adm_bpe_bankbn_drivers d
    ON d.codmes = c.codmes AND d.tip_doc = c.tip_doc AND d.key_value = c.key_value
INNER JOIN (
    SELECT CAST(codmes AS VARCHAR) AS cm, tip_doc, key_value,
           CAST(cod_instit_financiera AS VARCHAR) AS ent,
           sum(CASE WHEN substr(cod_cuenta_rcc,1,2) = '14' THEN 1 ELSE 0 END) AS n14,
           sum(CASE WHEN substr(cod_cuenta_rcc,1,2) = '72' THEN 1 ELSE 0 END) AS n72
    FROM e_perm_aws.t_fact_report_rcc_rsk
    WHERE p_codmes BETWEEN '202206' AND '202506'
      AND cast(tipo_credito AS int) BETWEEN 8 AND 10
    GROUP BY CAST(codmes AS VARCHAR), tip_doc, key_value, CAST(cod_instit_financiera AS VARCHAR)
) r
    ON r.cm = CAST(c.codmes AS VARCHAR) AND r.tip_doc = c.tip_doc
   AND r.key_value = c.key_value AND r.ent = CAST(c.cod_instit_financiera AS VARCHAR)
WHERE CAST(c.codmes AS VARCHAR) BETWEEN '202206' AND '202506'
  AND c.flg_clean IN (0, 1)
  AND c.target_12m IS NOT NULL
GROUP BY c.entidad,
         CASE WHEN c.flg_clean = 1 THEN 'clean' ELSE 'dirty' END,
         CASE WHEN d.dias_atraso_12m IS NULL THEN '1_ciego' ELSE '2_observado' END,
         CASE WHEN r.n14 > 0 THEN 'con_desembolso_m0' ELSE 'solo_contingente_m0' END
ORDER BY c.entidad, bucket, estado, origen
