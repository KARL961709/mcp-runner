-- 25_rd_entidad_anio.sql | tasa de malos a 12m por entidad y anio sobre la ventana madura, para dimensionar si un solo segmento global sostiene la calibracion
SELECT nombre_instit_financiera,
       substr(p_codmes, 1, 4)                                                                  AS anio,
       sum(CASE WHEN dsc_flg_malo_12m IN ('BUENO', 'MALO') AND prelacion_12m = 1
                 AND score IS NOT NULL THEN 1 ELSE 0 END)                                      AS n_per12,
       sum(CASE WHEN dsc_flg_malo_12m = 'MALO' AND prelacion_12m = 1
                 AND score IS NOT NULL THEN 1 ELSE 0 END)                                      AS n_malo12,
       round(100.0 * sum(CASE WHEN dsc_flg_malo_12m = 'MALO' AND prelacion_12m = 1
                              AND score IS NOT NULL THEN 1 ELSE 0 END)
             / nullif(sum(CASE WHEN dsc_flg_malo_12m IN ('BUENO', 'MALO') AND prelacion_12m = 1
                                AND score IS NOT NULL THEN 1 ELSE 0 END), 0), 3)               AS rd_12m,
       round(avg(TRY_CAST(score AS DOUBLE)), 1)                                                AS score_medio
FROM e_perm_aws.ds_flg_admtcnobk1_rsk
WHERE p_codmes <= '202601'
  AND flg_est = 1
GROUP BY nombre_instit_financiera, substr(p_codmes, 1, 4)
HAVING sum(CASE WHEN dsc_flg_malo_12m IN ('BUENO', 'MALO') AND prelacion_12m = 1
                 AND score IS NOT NULL THEN 1 ELSE 0 END) > 0
ORDER BY nombre_instit_financiera, anio
