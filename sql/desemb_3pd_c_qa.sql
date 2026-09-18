-- desemb_3pd_c_qa.sql | QA de la tabla 3 PDs (read-only -> _resultados.txt). Corre despues del build.
--   [1] COMPLETITUD POR MES: filas, cuantas SIN pd_cal_pit / SIN pd_opt_v2, y PD prom. Aqui se ve si algun mes quedo sin calculo.
SELECT cod_mes,
       COUNT(*) AS n,
       COUNT(*) - COUNT(pd_cal_pit) AS sin_pd_cal_pit,
       COUNT(*) - COUNT(pd_opt_v2)  AS sin_pd_opt_v2,
       ROUND(100*AVG(pd_cal_pit),2) AS pd_cal_pit_avg,
       ROUND(100*AVG(CASE WHEN meses_madurez=12 THEN target_12m END),2) AS rd12_mad
FROM disc_model_owner.b46029_desemb_3pd_202609
GROUP BY cod_mes ORDER BY cod_mes;

-- [2] RESUMEN GLOBAL + rangos (pd_cal_pit debe estar en (0,1), sin nulos salvo pd_opt_v2 por cobertura)
SELECT COUNT(*) AS total,
       COUNT(*) - COUNT(pd_cal_pit) AS sin_pd_cal_pit,
       COUNT(*) - COUNT(pd_opt_v2)  AS sin_pd_opt_v2,
       ROUND(100*MIN(pd_cal_pit),3) AS min_pit, ROUND(100*MAX(pd_cal_pit),3) AS max_pit,
       ROUND(100*MIN(pd_opt_v2),3)  AS min_v2,  ROUND(100*MAX(pd_opt_v2),3)  AS max_v2,
       COUNT(DISTINCT desc_cliente) AS n_desc_cliente
FROM disc_model_owner.b46029_desemb_3pd_202609;

-- [3] desc_cliente distintos (para detectar valores fuera de NUEVO/RECURRENTE que romperian el segmento)
SELECT desc_cliente, COUNT(*) AS n, COUNT(*) - COUNT(pd_cal_pit) AS sin_pit
FROM disc_model_owner.b46029_desemb_3pd_202609 GROUP BY desc_cliente ORDER BY 2 DESC;
