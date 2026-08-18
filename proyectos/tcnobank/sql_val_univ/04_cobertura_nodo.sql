-- 04. DE QUE SE ALIMENTA EL NODO EN ESTA POBLACION
--   las tres fuentes de comportamiento son internas de Interbank y esta PO es
--   mucho mas ancha que su base de clientes, asi que un N3 masivo es lo esperado
--   y hay que reportarlo, no corregirlo. prom_fuentes es la magnitud
SELECT nodo_calc,
       COUNT(*)                                                                  AS n,
       100.0 * COUNT(*) / SUM(COUNT(*)) OVER ()                                  AS pct,
       AVG(CAST(ctrl_nodo_n_fuentes AS DOUBLE))                                  AS prom_fuentes,
       100.0 * SUM(CASE WHEN ctrl_nodo_observado = 0 THEN 1 ELSE 0 END) / COUNT(*) AS pct_sin_ninguna,
       100.0 * SUM(CASE WHEN seg_arq_salud IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS pct_arq_nulo,
       AVG(prob_modelo_cal)                                                      AS pd_nueva_prom
  FROM disc_model_owner.scr_univ_vcnbank_tc_cal
 GROUP BY nodo_calc
 ORDER BY 1
