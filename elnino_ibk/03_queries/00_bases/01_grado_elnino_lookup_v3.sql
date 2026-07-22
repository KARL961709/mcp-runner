-- ============================================================
-- 01 · LOOKUP armonizada de grados R0-R5 para el JOIN por NOMBRE
-- ============================================================
-- Prerrequisito: la tabla científica disc_model_owner.grado_elnino_ubigeo_v3
--   se crea con el pipeline (02_pipeline/gen_v3_sql.js -> out/_v3_create.sql,
--   ejecutado vía AWS CLI por su tamaño ~167KB).
--
-- Esta lookup corrige defectos de nomenclatura para maximizar el match por
-- nombre (dep+prov+dist) con la cartera RENIEC (cod_ubi_domicilio NO homologado):
--   - 5 filas ICA/Nasca con prov/dist vacíos por comillas embebidas en el CSV
--   - Imperial (Cañete): 'CAETE' -> 'CANETE' (ñ mal folded)
--   - alias INEI: PUEBLO LIBRE (Lima) = MAGDALENA VIEJA (R1)
-- Cobertura resultante sobre cartera TC: 99.15%. JOIN oficial = por NOMBRE.
-- ============================================================
CREATE TABLE disc_model_owner.grado_elnino_lookup_v3 AS
WITH base AS (
  SELECT
    upper(trim(departamento)) AS dep,
    CASE WHEN cod_ubigeo IN ('110301','110302','110303','110304','110305') THEN 'NASCA'
         WHEN cod_ubigeo='150507' THEN 'CANETE'
         ELSE upper(trim(provincia)) END AS prov,
    CASE WHEN cod_ubigeo='110301' THEN 'NAZCA'
         ELSE upper(trim(distrito)) END AS dist,
    cod_ubigeo, cuenca, pacifico, n_eventos, pct_expuesto, score, r_nivel, r_label, patron_evento,
    'base' AS origen
  FROM disc_model_owner.grado_elnino_ubigeo_v3
)
SELECT * FROM base
UNION ALL
SELECT dep, prov, 'PUEBLO LIBRE' AS dist, cod_ubigeo, cuenca, pacifico, n_eventos,
       pct_expuesto, score, r_nivel, r_label, patron_evento, 'alias' AS origen
FROM base WHERE cod_ubigeo='150121';
