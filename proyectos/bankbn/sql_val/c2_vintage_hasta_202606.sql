-- c2_vintage_hasta_202606.sql | curva de maduracion por cosecha: los horizontes cortos ven hasta 202605, el 12m solo hasta 202506
SELECT CAST(codmes AS VARCHAR)                                    AS codmes,
       CASE WHEN flg_clean = 1 THEN 'clean' ELSE 'dirty' END      AS bucket,
       count(1)                                                   AS n,
       round(100.0 * avg(pd_raw), 3)                              AS pd_vig_pct,
       count(target_01m)                                          AS mad_01m,
       round(100.0 * sum(target_01m) / nullif(count(target_01m),0), 3) AS rd_01m,
       round(100.0 * sum(target_03m) / nullif(count(target_03m),0), 3) AS rd_03m,
       round(100.0 * sum(target_06m) / nullif(count(target_06m),0), 3) AS rd_06m,
       round(100.0 * sum(target_09m) / nullif(count(target_09m),0), 3) AS rd_09m,
       round(100.0 * sum(target_12m) / nullif(count(target_12m),0), 3) AS rd_12m,
       sum(target_01m)                                            AS malos_01m,
       sum(target_06m)                                            AS malos_06m,
       sum(target_12m)                                            AS malos_12m
FROM disc_model_owner.ds_adm_bpe_bankbn_cal
WHERE entidad = 'IBK'
  AND flg_clean IN (0, 1)
  AND pd_raw IS NOT NULL
GROUP BY CAST(codmes AS VARCHAR),
         CASE WHEN flg_clean = 1 THEN 'clean' ELSE 'dirty' END
ORDER BY bucket, codmes
