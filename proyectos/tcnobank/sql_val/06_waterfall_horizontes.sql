-- 06_waterfall_horizontes.sql | compara la cascada a 6, 9 y 12 meses para medir cuanto mueve el horizonte de maduracion a cada motivo de exclusion
SELECT h.horizonte,
       h.motivo,
       count(*)                                            AS n,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY h.horizonte), 3) AS pct
FROM e_perm_aws.ds_flg_admtcnobk1_rsk t
CROSS JOIN UNNEST(ARRAY['06m', '09m', '12m'],
                  ARRAY[t.dsc_flg_malo_06m, t.dsc_flg_malo_09m, t.dsc_flg_malo_12m]) AS h (horizonte, motivo)
GROUP BY h.horizonte, h.motivo
ORDER BY h.horizonte, n DESC
