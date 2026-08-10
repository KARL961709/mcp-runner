-- 101_target_semantica.sql | el target mide lo que decimos? Contrasta target_12m contra la cascada flag_malo_12m y contra los dias de atraso observados. Si el target es 90+ dias, MALO debe dar target=1 al 100% y con atraso sobre 90
SELECT COALESCE(flag_malo_12m, '(NULO)')                                         AS categoria,
       count(1)                                                                  AS n,
       sum(CASE WHEN target_12m = 1 THEN 1 ELSE 0 END)                           AS target_1,
       sum(CASE WHEN target_12m = 0 THEN 1 ELSE 0 END)                           AS target_0,
       sum(CASE WHEN target_12m IS NULL THEN 1 ELSE 0 END)                       AS target_nulo,
       round(100.0 * sum(CASE WHEN target_12m = 1 THEN 1 ELSE 0 END)
             / nullif(count(target_12m), 0), 2)                                  AS pct_target_1,
       min(dias_atraso_12m)                                                      AS atraso_min,
       approx_percentile(dias_atraso_12m, 0.5)                                   AS atraso_p50,
       max(dias_atraso_12m)                                                      AS atraso_max,
       sum(CASE WHEN target_12m = 1 AND dias_atraso_12m <= 90 THEN 1 ELSE 0 END) AS malo_con_atraso_bajo,
       sum(CASE WHEN target_12m = 0 AND dias_atraso_12m > 90 THEN 1 ELSE 0 END)  AS bueno_con_atraso_alto
FROM disc_model_owner.ds_adm_bpe_bankbn_mad
GROUP BY COALESCE(flag_malo_12m, '(NULO)')
ORDER BY n DESC
