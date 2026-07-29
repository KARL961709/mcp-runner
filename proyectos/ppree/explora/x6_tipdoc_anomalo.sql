-- x6  cod_tip_doc: x3 detecto un unico registro cuyo valor empieza en cero
-- Se perfila el dominio completo para saber si es un valor legitimo o un defecto
SELECT CAST(cod_tip_doc AS VARCHAR) AS cod_tip_doc,
       COUNT(*)                     AS n_filas,
       COUNT(DISTINCT key_value)    AS n_llaves,
       CAST(MIN(codmes) AS VARCHAR) AS mes_min,
       CAST(MAX(codmes) AS VARCHAR) AS mes_max
FROM disc_riesgos.t_b39918_scr_stockpp_itc_reprocesov4
GROUP BY CAST(cod_tip_doc AS VARCHAR)
ORDER BY 2 DESC
