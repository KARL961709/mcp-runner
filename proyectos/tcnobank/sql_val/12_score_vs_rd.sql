-- 12_score_vs_rd.sql | tasa de malos por tramo de score en la base con target observable, para ver si el score vigente ordena y con que nivel arranca la calibracion
SELECT CASE WHEN score IS NULL   THEN '00.sin score'
            WHEN score < 600     THEN '01.<600'
            WHEN score < 650     THEN '02.600-649'
            WHEN score < 700     THEN '03.650-699'
            WHEN score < 750     THEN '04.700-749'
            WHEN score < 800     THEN '05.750-799'
            WHEN score < 850     THEN '06.800-849'
            WHEN score < 900     THEN '07.850-899'
            WHEN score < 950     THEN '08.900-949'
            ELSE '09.950+' END                                          AS tramo_score,
       count(*)                                                         AS n,
       sum(CASE WHEN dsc_flg_malo_12m = 'MALO' THEN 1 ELSE 0 END)       AS n_malo,
       round(100.0 * sum(CASE WHEN dsc_flg_malo_12m = 'MALO' THEN 1 ELSE 0 END) / count(*), 3) AS rd_12m,
       min(score)                                                       AS score_min,
       max(score)                                                       AS score_max
FROM e_perm_aws.ds_flg_admtcnobk1_rsk
WHERE dsc_flg_malo_12m IN ('BUENO', 'MALO')
  AND prelacion_12m = 1
GROUP BY 1
ORDER BY 1
