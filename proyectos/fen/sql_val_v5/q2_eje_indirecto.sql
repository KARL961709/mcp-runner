-- q2 EJE INDIRECTO. Esperado: D0 758 D1 673 D2 322 D3 101 D4 36
SELECT d_label,
       count(*)                        AS n,
       round(avg(d_recurrencia), 2)    AS recurrencia_prom,
       min(d_recurrencia)              AS rec_min,
       max(d_recurrencia)              AS rec_max,
       count(DISTINCT d_evidencia)     AS n_tipos_evidencia
FROM disc_model_owner.fen_score_v5
GROUP BY d_label
ORDER BY d_label
