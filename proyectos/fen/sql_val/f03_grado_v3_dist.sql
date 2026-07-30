-- f03 DISTRIBUCION R0-R5 en Athena contra el CSV local
--     esperado: R0 1117 | R1 66 | R2 198 | R3 301 | R4 139 | R5 69  (total 1890)
SELECT r_label,
       count(*)                                AS n_distritos,
       sum(pacifico)                           AS n_pacifico,
       round(avg(CAST(n_eventos AS double)),2) AS ev_prom,
       round(avg(pct_expuesto),1)              AS pct_exp_prom,
       round(min(score),3)                     AS score_min,
       round(max(score),3)                     AS score_max
FROM disc_model_owner.grado_elnino_ubigeo_v3
GROUP BY r_label
ORDER BY r_label
