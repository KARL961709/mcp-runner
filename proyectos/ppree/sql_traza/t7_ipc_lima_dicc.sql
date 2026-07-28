-- t7  diccionario BCRP filtrado a los tickers de IPC de Lima
-- PN01271PM es el que usa REE (variacion mensual), PN01273PM y PN01283PM son sus vecinos
-- Objetivo: leer unidad, frecuencia y definicion para saber QUE mide cada uno
SELECT ticker, nombre, unidad, escala, frecuencia, fecha_inicio, fecha_fin,
       en_uso_actual, en_origen, en_curada_pp, nombre_amigable, categoria_pp,
       n_obs_api, validado_api, definicion
FROM disc_model_owner.bcrp_e2ea_rsk_dicc
WHERE ticker IN ('PN01271PM', 'PN01273PM', 'PN01283PM', 'PN01270PM', 'PN01272PM')
   OR (LOWER(nombre) LIKE '%ipc%' AND LOWER(nombre) LIKE '%lima%')
   OR (LOWER(definicion) LIKE '%indice de precios al consumidor%' AND LOWER(definicion) LIKE '%lima%')
ORDER BY ticker
LIMIT 30
