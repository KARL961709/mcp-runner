-- c_2609_modelo. Que es la columna modelo en vcbankv3_repro a 202609 (DNI): cuantos valores, si abre grano.
--   n ~ n_pers por modelo -> no hay fan-out (el driver rn=1 es seguro). Si un modelo abre a >1 fila/persona,
--   habria que filtrar el driver a ese modelo. avg_pd por modelo ayuda a identificar el score VC.
SELECT modelo, COUNT(*) AS n, COUNT(DISTINCT key_value) AS n_pers,
  ROUND(AVG(CAST(probabilidad AS double)), 6) AS avg_pd,
  ROUND(MIN(CAST(probabilidad AS double)), 6) AS min_pd,
  ROUND(MAX(CAST(probabilidad AS double)), 6) AS max_pd
FROM disc_riesgos.scr_vcbankv3_repro_
WHERE CAST(codmes AS varchar) = '202609' AND CAST(cod_tip_doc AS varchar) = '1'
GROUP BY modelo
ORDER BY n DESC
