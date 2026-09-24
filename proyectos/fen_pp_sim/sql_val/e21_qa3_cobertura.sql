-- e21_qa3_cobertura.sql | QA cobertura del nuevo s contra la poblacion real (celdas del sim, ubigeo INEI ya resuelto)
-- esperado: la gran mayoria con s, sin-dato (lo peor) marginal, SIN_GEO/000000 ~10% (pass-through)
SELECT SUM(c.n) AS clientes_total,
       SUM(CASE WHEN s.ubigeo IS NOT NULL THEN c.n ELSE 0 END) AS clientes_con_s,
       ROUND(100.0*SUM(CASE WHEN s.ubigeo IS NOT NULL THEN c.n ELSE 0 END)/SUM(c.n),2) AS pct_con_s,
       SUM(CASE WHEN s.ubigeo IS NULL AND c.ubigeo NOT IN ('SIN_GEO','000000') THEN c.n ELSE 0 END) AS clientes_sin_dato_lopeor,
       SUM(CASE WHEN c.ubigeo IN ('SIN_GEO','000000') THEN c.n ELSE 0 END) AS clientes_singeo_passthrough,
       COUNT(DISTINCT CASE WHEN s.ubigeo IS NULL AND c.ubigeo NOT IN ('SIN_GEO','000000') THEN c.ubigeo END) AS ubigeos_sin_dato
FROM disc_model_owner.fen_pp_sim_celdas_202609 c
LEFT JOIN disc_model_owner.fen_s_indirecto_empleo_2026 s ON s.ubigeo = c.ubigeo