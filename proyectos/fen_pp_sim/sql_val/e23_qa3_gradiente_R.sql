-- e23_qa3_gradiente_R.sql | QA gradiente por R (FEN). esc2/esc4 deben subir con R. esc3 (macro, sin FEN) casi plano en R
SELECT r_reest,
  COUNT(*) AS n,
  ROUND(100*AVG(pd_esc1_base),2)           AS esc1,
  ROUND(100*AVG(pd_esc2_fen70),2)          AS esc2_fen,
  ROUND(100*AVG(pd_esc3_macropes),2)       AS esc3_macro,
  ROUND(100*AVG(pd_esc4_macropes_fen50),2) AS esc4_pes_fen
FROM disc_model_owner.fen_pd_escenarios_2609
GROUP BY r_reest
ORDER BY r_reest