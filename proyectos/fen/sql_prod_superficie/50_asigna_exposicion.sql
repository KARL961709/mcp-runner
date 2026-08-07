-- Asigna a cada cliente del stock la exposicion FEN de los 5 puntos de la superficie mas
-- cercanos a su coordenada, y la centra dentro de su distrito para que el agregado no se mueva.
-- OJO: la salida lleva key_value. NO SACAR DE LA RED. Revisar el resultado alla.
CREATE TABLE disc_model_owner.fen_exposicion_cliente
WITH (format = 'PARQUET', external_location = '<S3_DATOS>/fen/fen_exposicion_cliente/') AS
WITH cli AS (
  SELECT g.key_value,
         g.longitud_x AS x, g.latitud_y AS y, d.ubigeo_cd AS ubigeo,
         CAST(FLOOR(g.longitud_x / 0.02) AS INTEGER) AS bx,
         CAST(FLOOR(g.latitud_y  / 0.02) AS INTEGER) AS by
  FROM e_perm_aws.t_agg_censo_enrich_rsk g
  JOIN e_perm_aws.t_dim_cliente d ON d.key_value = g.key_value
  WHERE g.longitud_x BETWEEN -82 AND -68
    AND g.latitud_y  BETWEEN -19 AND 1
),
par AS (
  SELECT c.key_value, c.ubigeo, s.exp_inundacion, s.exp_mov_masa,
         POWER((s.lon - c.x) * 111.32 * COS(RADIANS(c.y)), 2)
       + POWER((s.lat - c.y) * 110.57, 2) AS d2
  FROM cli c
  JOIN disc_model_owner.fen_superficie_exp s
    ON s.bx BETWEEN c.bx - 2 AND c.bx + 2
   AND s.by BETWEEN c.by - 2 AND c.by + 2
),
rk AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY key_value ORDER BY d2) AS n FROM par
),
ec AS (
  SELECT key_value, ubigeo,
         AVG(exp_inundacion) AS e_inu,
         AVG(exp_mov_masa)   AS e_mm,
         SQRT(MIN(d2))       AS km_al_punto_mas_cercano
  FROM rk WHERE n <= 5 GROUP BY key_value, ubigeo
)
SELECT e.key_value, e.ubigeo, e.e_inu, e.e_mm, e.km_al_punto_mas_cercano,
       e.e_inu / NULLIF(m.mu_inu, 0) - 1 AS et_inu,
       e.e_mm  / NULLIF(m.mu_mm , 0) - 1 AS et_mm
FROM ec e
JOIN (SELECT ubigeo, AVG(e_inu) AS mu_inu, AVG(e_mm) AS mu_mm
      FROM ec GROUP BY ubigeo) m ON m.ubigeo = e.ubigeo
