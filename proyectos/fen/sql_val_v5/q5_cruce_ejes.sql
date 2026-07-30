-- q5 MATRIZ de los dos ejes. Los ejes deben discrepar donde los peligros difieren:
--   R5 con D0 = lluvia pura | R0 con D3+ = sequia pura
SELECT r_label, d_label, count(*) AS n
FROM disc_model_owner.fen_score_v5
GROUP BY r_label, d_label
ORDER BY r_label, d_label
