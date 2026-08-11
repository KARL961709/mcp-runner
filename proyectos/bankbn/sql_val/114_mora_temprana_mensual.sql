-- 114_mora_temprana_mensual.sql | mora 30d y 60d a 3 meses por codmes y poblacion, contra la pd_raw del mismo mes. Responde si lo que el modelo predice como subida se esta viendo o no en el comportamiento observado
SELECT codmes,
       pob,
       flg_clean,
       count(*)                                            AS n,
       round(100.0 * avg(pd_crudo), 4)                     AS pd_raw,
       round(100.0 * avg(pd_pit), 4)                       AS pd_pit,
       sum(mora30_3m)                                      AS n_mora30_3m,
       round(100.0 * avg(CAST(mora30_3m AS DOUBLE)), 4)    AS mora30_3m,
       sum(mora60_3m)                                      AS n_mora60_3m,
       round(100.0 * avg(CAST(mora60_3m AS DOUBLE)), 4)    AS mora60_3m,
       sum(mora30_1m)                                      AS n_mora30_1m,
       round(100.0 * avg(CAST(mora30_1m AS DOUBLE)), 4)    AS mora30_1m,
       sum(sin_rcc)                                        AS n_sin_rcc,
       round(100.0 * avg(CAST(pjj AS DOUBLE)), 2)          AS pct_pjj
FROM (
    SELECT p.cm                                                                            AS codmes,
           p.pob,
           p.flg_clean,
           p.pd_crudo,
           p.pd_pit,
           p.pjj,
           CASE WHEN max(CASE WHEN r.codmes <= p.cm1 THEN r.dm END) > 30 THEN 1 ELSE 0 END AS mora30_1m,
           CASE WHEN max(r.dm) > 30 THEN 1 ELSE 0 END                                      AS mora30_3m,
           CASE WHEN max(r.dm) > 60 THEN 1 ELSE 0 END                                      AS mora60_3m,
           CASE WHEN count(r.dm) = 0 THEN 1 ELSE 0 END                                     AS sin_rcc
    FROM (
        SELECT CAST(tip_doc AS VARCHAR)               AS td,
               CAST(key_value AS VARCHAR)             AS kv,
               CAST(cod_instit_financiera AS VARCHAR) AS ent,
               CAST(codmes AS VARCHAR)                AS cm,
               date_format(date_parse(CAST(codmes AS VARCHAR), '%Y%m') + interval '1' month, '%Y%m') AS cm1,
               date_format(date_parse(CAST(codmes AS VARCHAR), '%Y%m') + interval '3' month, '%Y%m') AS cm3,
               CASE WHEN entidad = 'IBK' THEN 'IBK'
                    WHEN entidad = 'OTRO' THEN 'SSFF'
                    ELSE 'RESTO_TOP4' END             AS pob,
               flg_clean,
               TRY_CAST(flg_ppjj AS INTEGER)          AS pjj,
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
    GROUP BY p.td, p.kv, p.cm, p.pob, p.flg_clean, p.pd_crudo, p.pd_pit, p.pjj
) q
GROUP BY codmes, pob, flg_clean
ORDER BY pob, flg_clean, codmes
