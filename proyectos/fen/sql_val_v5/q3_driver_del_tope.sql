-- q3 DRIVER dentro del tope del eje directo. Esperado en R4+R5 (n=198):
--   severidad 77 | mixto 68 | recurrencia 53
-- recurrencia = el nivel se sostiene en activacion y exposicion, NO en dano propio
SELECT r_label, r_driver,
       count(*)                  AS n,
       round(avg(sev), 3)        AS sev_prom,
       round(avg(score), 2)      AS score_prom
FROM disc_model_owner.fen_score_v5
WHERE r_label IN ('R4', 'R5')
GROUP BY r_label, r_driver
ORDER BY r_label DESC, n DESC
