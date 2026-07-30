-- v4_20 QA de la tabla v4 -- read-only. Esperado (medido en el CSV local):
--   R0 1297 (1117 no_pac + 180 cronica) | R1 45 | R2 130 | R3 240 | R4 112 | R5 66 | total 1890
SELECT r_label,
       count(*)                                                     AS n_distritos,
       sum(pacifico)                                                AS n_pacifico,
       sum(gate_cronica)                                            AS n_gate_cronica,
       count(DISTINCT patron_evento)                                AS n_patrones,
       round(avg(pct_expuesto), 1)                                  AS pct_exp_prom,
       round(min(lift_cuenca), 2)                                   AS lift_min,
       round(max(lift_cuenca), 2)                                   AS lift_max
FROM disc_model_owner.grado_elnino_ubigeo_v4
GROUP BY r_label
ORDER BY r_label
