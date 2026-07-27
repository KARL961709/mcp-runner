-- u2_sentinela_9999.sql | 9999 es tope o centinela, no dias: cuanto del target=1 sale de ahi y de valores implausibles
SELECT CASE WHEN dias_atraso_12m IS NULL       THEN '0_NULL'
            WHEN dias_atraso_12m = 0           THEN '1_cero'
            WHEN dias_atraso_12m <= 90         THEN '2_de_1_a_90'
            WHEN dias_atraso_12m <= 365        THEN '3_de_91_a_365'
            WHEN dias_atraso_12m <= 1095       THEN '4_de_366_a_1095'
            WHEN dias_atraso_12m < 9999        THEN '5_de_1096_a_9998'
            ELSE '6_igual_9999' END                                        AS banda,
       count(1)                                                            AS n,
       round(100.0 * count(1) / sum(count(1)) OVER (), 3)                   AS pct_universo,
       sum(target_12m)                                                     AS n_malo_12m,
       sum(CASE WHEN target_12m = 1
                 AND COALESCE(jud_12um,0) = 0 AND COALESCE(cast_12um,0) = 0
                 AND COALESCE(ref_12um,0) = 0 AND COALESCE(ree_12um,0) = 0
                THEN 1 ELSE 0 END)                                         AS n_malo_solo_por_mora,
       min(dias_atraso_12m)                                                AS dias_min,
       max(dias_atraso_12m)                                                AS dias_max
FROM disc_model_owner.ds_adm_bpe_bankbn_mad
GROUP BY CASE WHEN dias_atraso_12m IS NULL       THEN '0_NULL'
              WHEN dias_atraso_12m = 0           THEN '1_cero'
              WHEN dias_atraso_12m <= 90         THEN '2_de_1_a_90'
              WHEN dias_atraso_12m <= 365        THEN '3_de_91_a_365'
              WHEN dias_atraso_12m <= 1095       THEN '4_de_366_a_1095'
              WHEN dias_atraso_12m < 9999        THEN '5_de_1096_a_9998'
              ELSE '6_igual_9999' END
ORDER BY banda
