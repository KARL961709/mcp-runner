-- s02 seed fen_ibk_plus: IBK+ centrado (depto-nac) por POBLACION y su periodo coherente. ibk_c_altas = centrado del promedio 202605-202607 (ventana de las altas j03); ibk_c_pea = centrado de 202608 (mes de la PEA, proyeccion Ago-26). Valores del PANEL IBK+ mas reciente (pegado por Carlos, hasta Set-26; guardado en elnino_ibk/01_inputs/ibk_plus/ibk_panel_reciente_202609.csv). nac avg605-607=3.200, nac 608=3.3. 12 deptos con serie propia; el resto = nacional (LEFT JOIN nulo -> coalesce 0). Resiliente = centrado > 0. NUNCA sube el estres: aguas abajo entra como max(ibk_c,0). depto = codigo INEI 2 digitos. OJO 607/608/609 son PROYECCION
CREATE TABLE disc_model_owner.fen_ibk_plus
WITH (format='PARQUET', write_compression='SNAPPY', external_location='<S3_DATOS>/fen_ibk_plus/') AS
SELECT depto, nombre, ibk_altas, ibk_pea, ibk_c_altas, ibk_c_pea,
  CASE WHEN ibk_c_altas > 0 THEN 1 ELSE 0 END AS resil_altas,
  CASE WHEN ibk_c_pea   > 0 THEN 1 ELSE 0 END AS resil_pea
FROM (VALUES
  (CAST('02' AS varchar), CAST('ANCASH'      AS varchar), 2.667, 2.7, -0.533, -0.600),
  ('04', 'AREQUIPA',    3.267, 3.1,  0.067, -0.200),
  ('06', 'CAJAMARCA',   2.200, 1.8, -1.000, -1.500),
  ('08', 'CUSCO',       2.867, 3.2, -0.333, -0.100),
  ('11', 'ICA',         4.100, 3.9,  0.900,  0.600),
  ('12', 'JUNIN',       1.867, 1.9, -1.333, -1.400),
  ('13', 'LA LIBERTAD', 2.733, 2.9, -0.467, -0.400),
  ('14', 'LAMBAYEQUE',  1.200, 0.9, -2.000, -2.400),
  ('15', 'LIMA',        3.700, 3.9,  0.500,  0.600),
  ('16', 'LORETO',      2.333, 2.6, -0.867, -0.700),
  ('20', 'PIURA',       3.267, 3.3,  0.067,  0.000),
  ('21', 'PUNO',        2.567, 3.1, -0.633, -0.200)
) AS t(depto, nombre, ibk_altas, ibk_pea, ibk_c_altas, ibk_c_pea)
