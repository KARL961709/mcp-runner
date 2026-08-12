-- 05_waterfall_actual.sql | cobertura de cada filtro de la PO vigente: reparto completo de la cascada a 12 meses sobre el universo cliente-entidad
SELECT dsc_flg_malo_12m                                              AS motivo,
       count(*)                                                      AS n,
       round(100.0 * count(*) / sum(count(*)) OVER (), 3)            AS pct,
       count(DISTINCT p_codmes)                                      AS meses,
       sum(CASE WHEN prelacion_00m = 1 THEN 1 ELSE 0 END)            AS n_prelacion00,
       sum(CASE WHEN score IS NULL THEN 1 ELSE 0 END)                AS sin_score,
       sum(CASE WHEN flg_malo_orig = 1 THEN 1 ELSE 0 END)            AS n_malo_orig
FROM e_perm_aws.ds_flg_admtcnobk1_rsk
GROUP BY dsc_flg_malo_12m
ORDER BY n DESC
