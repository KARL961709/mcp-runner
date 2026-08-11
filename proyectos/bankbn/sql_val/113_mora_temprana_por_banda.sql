-- 113_mora_temprana_por_banda.sql | construye la mora 30d a 3 y 6 meses desde el RCC con la misma definicion de dm que la maduracion y la cruza contra la banda de PD calibrada, para probar si el nivel de v3 acierta en cada poblacion
SELECT pob,
       flg_clean,
       banda,
       count(*)                                          AS n,
       round(100.0 * avg(pd_pit), 4)                     AS pd_media,
       round(100.0 * avg(pd_crudo), 4)                   AS pd_raw_media,
       sum(mora30_3m)                                    AS n_mora30_3m,
       round(100.0 * avg(CAST(mora30_3m AS DOUBLE)), 4)  AS tasa_mora30_3m,
       sum(mora60_3m)                                    AS n_mora60_3m,
       round(100.0 * avg(CAST(mora60_3m AS DOUBLE)), 4)  AS tasa_mora60_3m,
       sum(mora30_6m)                                    AS n_mora30_6m,
       round(100.0 * avg(CAST(mora30_6m AS DOUBLE)), 4)  AS tasa_mora30_6m,
       sum(sin_rcc)                                      AS n_sin_rcc,
       count(t12)                                        AS n_eval_12m,
       sum(t12)                                          AS n_def_12m,
       round(100.0 * avg(CAST(t12 AS DOUBLE)), 4)        AS rd_12m
FROM (
    SELECT p.pob,
           p.flg_clean,
           p.banda,
           p.pd_pit,
           p.pd_crudo,
           p.t12,
           CASE WHEN max(CASE WHEN r.codmes <= p.cm3 THEN r.dm END) > 30 THEN 1 ELSE 0 END AS mora30_3m,
           CASE WHEN max(CASE WHEN r.codmes <= p.cm3 THEN r.dm END) > 60 THEN 1 ELSE 0 END AS mora60_3m,
           CASE WHEN max(r.dm) > 30 THEN 1 ELSE 0 END                                      AS mora30_6m,
           CASE WHEN count(r.dm) = 0 THEN 1 ELSE 0 END                                     AS sin_rcc
    FROM (
        SELECT CAST(tip_doc AS VARCHAR)   AS td,
               CAST(key_value AS VARCHAR) AS kv,
               CAST(cod_instit_financiera AS VARCHAR) AS ent,
               CAST(codmes AS VARCHAR)    AS cm,
               date_format(date_parse(CAST(codmes AS VARCHAR), '%Y%m') + interval '1' month, '%Y%m') AS cm1,
               date_format(date_parse(CAST(codmes AS VARCHAR), '%Y%m') + interval '3' month, '%Y%m') AS cm3,
               date_format(date_parse(CAST(codmes AS VARCHAR), '%Y%m') + interval '6' month, '%Y%m') AS cm6,
               CASE WHEN entidad = 'IBK' THEN 'IBK'
                    WHEN entidad = 'OTRO' THEN 'SSFF'
                    ELSE 'RESTO_TOP4' END AS pob,
               flg_clean,
               TRY_CAST(prob_modelo_cal AS DOUBLE) AS pd_pit,
               TRY_CAST(pd_raw AS DOUBLE)          AS pd_crudo,
               TRY_CAST(target_12m AS INTEGER)     AS t12,
               CASE WHEN TRY_CAST(prob_modelo_cal AS DOUBLE) <  0.02 THEN '01  menos de 2'
                    WHEN TRY_CAST(prob_modelo_cal AS DOUBLE) <  0.04 THEN '02  2 a 4'
                    WHEN TRY_CAST(prob_modelo_cal AS DOUBLE) <  0.06 THEN '03  4 a 6'
                    WHEN TRY_CAST(prob_modelo_cal AS DOUBLE) <  0.08 THEN '04  6 a 8'
                    WHEN TRY_CAST(prob_modelo_cal AS DOUBLE) <  0.10 THEN '05  8 a 10'
                    WHEN TRY_CAST(prob_modelo_cal AS DOUBLE) <  0.13 THEN '06  10 a 13'
                    WHEN TRY_CAST(prob_modelo_cal AS DOUBLE) <  0.16 THEN '07  13 a 16'
                    WHEN TRY_CAST(prob_modelo_cal AS DOUBLE) <  0.20 THEN '08  16 a 20'
                    WHEN TRY_CAST(prob_modelo_cal AS DOUBLE) <  0.30 THEN '09  20 a 30'
                    ELSE '10  30 o mas' END          AS banda
        FROM disc_model_owner.ds_adm_bpe_bankbn_cal_202607
        WHERE prob_modelo_cal IS NOT NULL
          AND codmes BETWEEN '202407' AND '202512'
    ) p
    LEFT JOIN (
        SELECT CAST(codmes AS VARCHAR)   AS codmes,
               CAST(tip_doc AS VARCHAR)  AS td,
               CAST(key_value AS VARCHAR) AS kv,
               CAST(cod_instit_financiera AS VARCHAR) AS ent,
               max(CASE WHEN CAST(tipo_credito AS INTEGER) BETWEEN 1 AND 10
                             AND ((substr(cod_cuenta_rcc,1,2) = '14'
                                   AND substr(cod_cuenta_rcc,7,2) NOT IN ('01','04')
                                   AND substr(cod_cuenta_rcc,4,1) IN ('1','3','4','5','6'))
                                  OR (substr(cod_cuenta_rcc,1,2) = '81'
                                      AND substr(cod_cuenta_rcc,4,3) IN ('302','925')))
                        THEN TRY_CAST(condicion AS INTEGER) END)   AS dm
        FROM e_perm_aws.t_fact_report_rcc_rsk
        WHERE p_codmes BETWEEN '202408' AND '202606'
          AND codmes   BETWEEN '202408' AND '202606'
        GROUP BY 1, 2, 3, 4
    ) r
      ON r.td  = p.td
     AND r.kv  = p.kv
     AND r.ent = p.ent
     AND r.codmes BETWEEN p.cm1 AND p.cm6
    GROUP BY p.td, p.kv, p.cm, p.pob, p.flg_clean, p.banda, p.pd_pit, p.pd_crudo, p.t12
) q
GROUP BY pob, flg_clean, banda
ORDER BY pob, flg_clean, banda
