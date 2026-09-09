-- s02 seed fen_ibk_plus: resiliencia IBK+ por depto y poblacion. METODOLOGIA (v2, 2026-09-09): desviacion de su PROPIA normal pre-FEN (mediana 202503-202602), NO vs promedio nacional, gate de recuperacion anclado al FEN costero previo Yaku-2023 (clawback = fraccion de la caida recuperada a 6m). ibk_c = atenuacion aplicada = desvio SOLO si el depto es RESILIENTE (hoy >= su normal Y recupero en Yaku), si no 0. desvio_altas = avg(202605,202606,202607) - normal, desvio_pea = 202608 - normal. Regimen: RESILIENTE (atenua) / VIGILAR (recupero en Yaku pero hoy < su normal, estres FEN-2026 temprano -> sin alivio) / FRAGIL (recupero lento en Yaku -> sin alivio). Valores del panel IBK+ mas reciente (elnino_ibk/01_inputs/ibk_plus/ibk_panel_reciente_202609.csv, hasta Set-26, 607/608/609 PROYECCION). Solo 12 deptos tienen serie propia, los otros 13 (incl. costeros Tumbes/Callao/Tacna/Moquegua) NO -> LEFT JOIN nulo -> coalesce(0) = tratados como el PEOR observado (Junin, clawback 0.12) -> sin alivio, nunca resilientes sin dato. Aguas abajo entra como max(ibk_c,0): NUNCA sube el estres. depto = codigo INEI 2 digitos.
CREATE TABLE disc_model_owner.fen_ibk_plus
WITH (format='PARQUET', write_compression='SNAPPY', external_location='<S3_DATOS>/fen_ibk_plus/') AS
SELECT depto, nombre, normal, ibk_altas, ibk_pea, desvio_altas, desvio_pea, yaku_claw, regimen, ibk_c_altas, ibk_c_pea,
  CASE WHEN ibk_c_altas > 0 THEN 1 ELSE 0 END AS resil_altas,
  CASE WHEN ibk_c_pea   > 0 THEN 1 ELSE 0 END AS resil_pea
FROM (VALUES
  (CAST('02' AS varchar), CAST('ANCASH' AS varchar), 2.08, 2.667, 2.7,  0.59,  0.62, 0.79, CAST('RESILIENTE' AS varchar), 0.59, 0.62),
  ('04', 'AREQUIPA',    2.86, 3.267, 3.1,  0.41,  0.24, 1.00, 'RESILIENTE', 0.41, 0.24),
  ('06', 'CAJAMARCA',   2.70, 2.200, 1.8, -0.50, -0.90, 1.00, 'VIGILAR',    0.00, 0.00),
  ('08', 'CUSCO',       1.98, 2.867, 3.2,  0.89,  1.22, 0.88, 'RESILIENTE', 0.89, 1.22),
  ('11', 'ICA',         3.40, 4.100, 3.9,  0.70,  0.50, 0.62, 'RESILIENTE', 0.70, 0.50),
  ('12', 'JUNIN',       1.85, 1.867, 1.9,  0.02,  0.05, 0.12, 'FRAGIL',     0.00, 0.00),
  ('13', 'LA LIBERTAD', 2.66, 2.733, 2.9,  0.07,  0.24, 0.41, 'RESILIENTE', 0.07, 0.24),
  ('14', 'LAMBAYEQUE',  1.80, 1.200, 0.9, -0.60, -0.90, 1.00, 'VIGILAR',    0.00, 0.00),
  ('15', 'LIMA',        3.36, 3.700, 3.9,  0.34,  0.54, 0.55, 'RESILIENTE', 0.34, 0.54),
  ('16', 'LORETO',      2.79, 2.333, 2.6, -0.46, -0.19, 0.15, 'FRAGIL',     0.00, 0.00),
  ('20', 'PIURA',       2.94, 3.267, 3.3,  0.33,  0.36, 1.00, 'RESILIENTE', 0.33, 0.36),
  ('21', 'PUNO',        2.20, 2.567, 3.1,  0.37,  0.90, 0.19, 'FRAGIL',     0.00, 0.00)
) AS t(depto, nombre, normal, ibk_altas, ibk_pea, desvio_altas, desvio_pea, yaku_claw, regimen, ibk_c_altas, ibk_c_pea)
