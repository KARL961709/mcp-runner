-- x1  contrato de la tabla nueva: todas sus columnas y tipos
-- No se asume ningun nombre: de aqui salen los nombres reales de PD, score y llaves
SELECT ordinal_position, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'disc_riesgos'
  AND table_name = 't_b39918_scr_stockpp_itc_reprocesov4'
ORDER BY ordinal_position
