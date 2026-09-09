-- qa01 salud del insumo fen_overlay_input_202608 (correr DESPUES de s03): cobertura de s e IBK+, distribucion de R (dir y reest), gate Pacifico y recorte por cada R. Confirma que el ~9.1M quedo sano antes de los escenarios. Una fila -> _resultados.txt
SELECT
  count(*) AS n,
  round(avg(CASE WHEN s_total IS NOT NULL THEN 1.0 ELSE 0.0 END), 4) AS cob_s,
  round(avg(CASE WHEN ibk_centrado > 0 THEN 1.0 ELSE 0.0 END), 4)    AS frac_ibk_atenua,
  sum(CASE WHEN r_dir   >= 1 THEN 1 ELSE 0 END) AS n_pac_dir,
  sum(CASE WHEN r_reest >= 1 THEN 1 ELSE 0 END) AS n_pac_reest,
  round(avg(CAST(r_dir   AS double)), 3) AS avg_r_dir,
  round(avg(CAST(r_reest AS double)), 3) AS avg_r_reest,
  sum(CASE WHEN r_dir   >= 4 THEN 1 ELSE 0 END) AS n_recorte_dir,
  sum(CASE WHEN r_reest >= 4 THEN 1 ELSE 0 END) AS n_recorte_reest
FROM disc_model_owner.fen_overlay_input_202608
