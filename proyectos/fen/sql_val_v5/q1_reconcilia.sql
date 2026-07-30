-- q1 RECONCILIACION contra el CSV local. Esperado:
--   total 1890 | R0 1271 R1 45 R2 130 R3 246 R4 129 R5 69
SELECT r_label,
       count(*)                                   AS n,
       count(DISTINCT cod_ubigeo)                 AS n_ubigeo,
       sum(marcado)                               AS n_marcados,
       round(avg(sev), 3)                         AS sev_prom,
       round(min(score), 2)                       AS score_min,
       round(max(score), 2)                       AS score_max
FROM disc_model_owner.fen_score_v5
GROUP BY r_label
ORDER BY r_label
