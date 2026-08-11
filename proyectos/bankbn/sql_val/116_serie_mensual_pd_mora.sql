-- 116_serie_mensual_pd_mora.sql | una fila por codmes con pd_raw, pd_pit y mora 30d a 3 meses para IBK, TOP 4 completo y SSFF. Bloque TOTAL, clean y dirty juntos. Columnas por poblacion para que entren las 39 filas sin que el resumen las trunque
SELECT codmes,
       sum(CASE WHEN pob = 'IBK'  THEN 1 ELSE 0 END)                                        AS ibk_n,
       round(100.0 * avg(CASE WHEN pob = 'IBK'  THEN pd_crudo END), 4)                      AS ibk_pd_raw,
       round(100.0 * avg(CASE WHEN pob = 'IBK'  THEN pd_pit   END), 4)                      AS ibk_pd_pit,
       sum(CASE WHEN pob = 'IBK'  THEN mora30_3m ELSE 0 END)                                AS ibk_ev_mora,
       round(100.0 * sum(CASE WHEN pob = 'IBK'  THEN mora30_3m ELSE 0 END)
             / nullif(sum(CASE WHEN pob = 'IBK'  THEN 1 ELSE 0 END), 0), 4)                 AS ibk_mora30_3m,
       sum(CASE WHEN pob <> 'SSFF' THEN 1 ELSE 0 END)                                       AS top4_n,
       round(100.0 * avg(CASE WHEN pob <> 'SSFF' THEN pd_crudo END), 4)                     AS top4_pd_raw,
       round(100.0 * avg(CASE WHEN pob <> 'SSFF' THEN pd_pit   END), 4)                     AS top4_pd_pit,
       sum(CASE WHEN pob <> 'SSFF' THEN mora30_3m ELSE 0 END)                               AS top4_ev_mora,
       round(100.0 * sum(CASE WHEN pob <> 'SSFF' THEN mora30_3m ELSE 0 END)
             / nullif(sum(CASE WHEN pob <> 'SSFF' THEN 1 ELSE 0 END), 0), 4)                AS top4_mora30_3m,
       sum(CASE WHEN pob = 'SSFF' THEN 1 ELSE 0 END)                                        AS ssff_n,
       round(100.0 * avg(CASE WHEN pob = 'SSFF' THEN pd_crudo END), 4)                      AS ssff_pd_raw,
       round(100.0 * avg(CASE WHEN pob = 'SSFF' THEN pd_pit   END), 4)                      AS ssff_pd_pit,
       sum(CASE WHEN pob = 'SSFF' THEN mora30_3m ELSE 0 END)                                AS ssff_ev_mora,
       round(100.0 * sum(CASE WHEN pob = 'SSFF' THEN mora30_3m ELSE 0 END)
             / nullif(sum(CASE WHEN pob = 'SSFF' THEN 1 ELSE 0 END), 0), 4)                 AS ssff_mora30_3m,
       sum(sin_rcc)                                                                         AS n_sin_rcc
FROM (
    SELECT p.cm AS codmes,
           p.pob,
           p.pd_crudo,
           p.pd_pit,
           CASE WHEN max(r.dm) > 30 THEN 1 ELSE 0 END  AS mora30_3m,
           CASE WHEN count(r.dm) = 0 THEN 1 ELSE 0 END AS sin_rcc
    FROM (
        SELECT CAST(tip_doc AS VARCHAR)               AS td,
               CAST(key_value AS VARCHAR)             AS kv,
               CAST(cod_instit_financiera AS VARCHAR) AS ent,
               CAST(codmes AS VARCHAR)                AS cm,
               date_format(date_parse(CAST(codmes AS VARCHAR), '%Y%m') + interval '1' month, '%Y%m') AS cm1,
               date_format(date_parse(CAST(codmes AS VARCHAR), '%Y%m') + interval '3' month, '%Y%m') AS cm3,
               CASE WHEN entidad = 'OTRO' THEN 'SSFF'
                    WHEN entidad = 'IBK'  THEN 'IBK'
                    ELSE 'RESTO_TOP4' END             AS pob,
               TRY_CAST(pd_raw AS DOUBLE)             AS pd_crudo,
               TRY_CAST(prob_modelo_cal AS DOUBLE)    AS pd_pit
        FROM disc_model_owner.ds_adm_bpe_bankbn_cal_202607
        WHERE pd_raw IS NOT NULL
          AND codmes BETWEEN '202301' AND '202603'
    ) p
    LEFT JOIN (
        SELECT CAST(codmes AS VARCHAR)                AS codmes,
               CAST(tip_doc AS VARCHAR)               AS td,
               CAST(key_value AS VARCHAR)             AS kv,
               CAST(cod_instit_financiera AS VARCHAR) AS ent,
               max(CASE WHEN CAST(tipo_credito AS INTEGER) BETWEEN 1 AND 10
                             AND ((substr(cod_cuenta_rcc,1,2) = '14'
                                   AND substr(cod_cuenta_rcc,7,2) NOT IN ('01','04')
                                   AND substr(cod_cuenta_rcc,4,1) IN ('1','3','4','5','6'))
                                  OR (substr(cod_cuenta_rcc,1,2) = '81'
                                      AND substr(cod_cuenta_rcc,4,3) IN ('302','925')))
                        THEN TRY_CAST(condicion AS INTEGER) END) AS dm
        FROM e_perm_aws.t_fact_report_rcc_rsk
        WHERE p_codmes BETWEEN '202302' AND '202606'
          AND codmes   BETWEEN '202302' AND '202606'
        GROUP BY 1, 2, 3, 4
    ) r
      ON r.td  = p.td
     AND r.kv  = p.kv
     AND r.ent = p.ent
     AND r.codmes BETWEEN p.cm1 AND p.cm3
    GROUP BY p.td, p.kv, p.cm, p.pob, p.pd_crudo, p.pd_pit
) q
GROUP BY codmes
ORDER BY codmes
