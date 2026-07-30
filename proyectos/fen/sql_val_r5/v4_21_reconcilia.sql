-- v4_21 RECONCILIACION de los dos motivos de R0 -- deben sumar exactamente el R0 total
SELECT patron_evento,
       count(*)                        AS n,
       sum(CASE WHEN r_label = 'R0' THEN 1 ELSE 0 END) AS n_en_r0,
       sum(pacifico)                   AS n_pacifico,
       round(avg(pct_expuesto), 1)     AS pct_exp_prom,
       round(avg(lift_cuenca), 2)      AS lift_prom
FROM disc_model_owner.grado_elnino_ubigeo_v4
GROUP BY patron_evento
ORDER BY 2 DESC
