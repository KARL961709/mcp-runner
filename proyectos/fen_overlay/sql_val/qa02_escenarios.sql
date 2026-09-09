-- qa02 escenarios (correr DESPUES de s05 dir + reest): por vista (dir/reest) y escenario -> impacto y control de calidad del motor. viola_monotonia y viola_pac0 DEBEN ser 0 (motor correcto: PDx>=pd0 siempre, y pac=0 no mueve nada). n_baja_grado / n_entra_gr = migracion por el estres. n_recorte = clientes R>=4 (RECHAZO). Sobre pd_ppfacil. 12 filas -> _resultados.txt
WITH u AS (
  SELECT 'dir' AS version, escenario, pac, recorte_duro, pd_base_facil, pd_estres_facil, grado_base_facil, grado_estres_facil
  FROM disc_model_owner.fen_overlay_escenarios_202608_dir
  UNION ALL
  SELECT 'reest' AS version, escenario, pac, recorte_duro, pd_base_facil, pd_estres_facil, grado_base_facil, grado_estres_facil
  FROM disc_model_owner.fen_overlay_escenarios_202608_reest
)
SELECT version, escenario,
  count(*) AS n,
  sum(pac) AS n_pac,
  round(avg(pd_base_facil), 5)   AS pd_base,
  round(avg(pd_estres_facil), 5) AS pd_estres,
  sum(CASE WHEN pd_estres_facil < pd_base_facil - 1e-9 THEN 1 ELSE 0 END) AS viola_monotonia,
  sum(CASE WHEN pac = 0 AND abs(pd_estres_facil - pd_base_facil) > 1e-9 THEN 1 ELSE 0 END) AS viola_pac0,
  sum(CASE WHEN grado_estres_facil <> grado_base_facil THEN 1 ELSE 0 END) AS n_baja_grado,
  sum(CASE WHEN grado_estres_facil = 'GR' AND grado_base_facil <> 'GR' THEN 1 ELSE 0 END) AS n_entra_gr,
  sum(recorte_duro) AS n_recorte
FROM u
GROUP BY version, escenario
ORDER BY version, escenario
