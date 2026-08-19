-- p2 | Codigos reales de subproducto en la madre raw. READ-ONLY.
--   Revela si P.Facil viene como '5.P FACIL', 'PFACIL', un codigo numerico, etc.
--   (si '%FACIL%' no matcheaba, aqui esta el porque).
SELECT subproducto, count(*) AS n
FROM disc_monitorian.t_mrm_mongest_altas_pp_marcas
GROUP BY subproducto
ORDER BY 2 DESC
LIMIT 20
