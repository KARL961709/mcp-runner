-- 115_prelacion_sesgo.sql | cuanto pesa la prelacion que asigna una sola entidad por cliente-mes priorizando IBK. Mide, para cada poblacion asignada, cuantos tienen ademas deuda simultanea en IBK o en el top 4, que es la diferencia entre la poblacion que analizamos y la que campanas prospecta
SELECT pob,
       flg_clean,
       count(*)                                                          AS n,
       sum(con_ibk)                                                      AS n_con_deuda_ibk,
       round(100.0 * avg(CAST(con_ibk AS DOUBLE)), 3)                    AS pct_con_deuda_ibk,
       sum(con_top4)                                                     AS n_con_deuda_top4,
       round(100.0 * avg(CAST(con_top4 AS DOUBLE)), 3)                   AS pct_con_deuda_top4,
       round(avg(CAST(n_entidades AS DOUBLE)), 3)                        AS prom_entidades,
       sum(CASE WHEN n_entidades = 1 THEN 1 ELSE 0 END)                  AS n_una_entidad,
       round(100.0 * avg(CASE WHEN n_entidades = 1 THEN 1.0 ELSE 0.0 END), 3) AS pct_una_entidad,
       round(100.0 * avg(pd_crudo), 4)                                   AS pd_raw,
       count(t12)                                                        AS n_eval,
       round(100.0 * avg(CAST(t12 AS DOUBLE)), 4)                        AS rd_12m
FROM (
    SELECT p.pob,
           p.flg_clean,
           p.pd_crudo,
           p.t12,
           count(DISTINCT r.ent)                                                  AS n_entidades,
           max(CASE WHEN r.ent = '00002' THEN 1 ELSE 0 END)                       AS con_ibk,
           max(CASE WHEN r.ent IN ('00001','00002','00004','00006') THEN 1 ELSE 0 END) AS con_top4
    FROM (
        SELECT CAST(tip_doc AS VARCHAR)            AS td,
               CAST(key_value AS VARCHAR)          AS kv,
               CAST(codmes AS VARCHAR)             AS cm,
               CASE WHEN entidad = 'IBK' THEN 'IBK'
                    WHEN entidad = 'OTRO' THEN 'SSFF'
                    ELSE 'RESTO_TOP4' END          AS pob,
               flg_clean,
               TRY_CAST(pd_raw AS DOUBLE)          AS pd_crudo,
               TRY_CAST(target_12m AS INTEGER)     AS t12
        FROM disc_model_owner.ds_adm_bpe_bankbn_cal_202607
        WHERE pd_raw IS NOT NULL
          AND codmes BETWEEN '202407' AND '202506'
    ) p
    LEFT JOIN (
        SELECT CAST(codmes AS VARCHAR)                AS codmes,
               CAST(tip_doc AS VARCHAR)               AS td,
               CAST(key_value AS VARCHAR)             AS kv,
               CAST(cod_instit_financiera AS VARCHAR) AS ent
        FROM e_perm_aws.t_fact_report_rcc_rsk
        WHERE p_codmes BETWEEN '202407' AND '202506'
          AND codmes   BETWEEN '202407' AND '202506'
          AND CAST(tipo_credito AS INTEGER) BETWEEN 1 AND 10
          AND substr(cod_cuenta_rcc,1,2) = '14'
          AND saldo > 0
        GROUP BY 1, 2, 3, 4
    ) r
      ON r.td = p.td AND r.kv = p.kv AND r.codmes = p.cm
    GROUP BY p.td, p.kv, p.cm, p.pob, p.flg_clean, p.pd_crudo, p.t12
) q
GROUP BY pob, flg_clean
ORDER BY pob, flg_clean
