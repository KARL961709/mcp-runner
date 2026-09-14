-- 14_userdesemb_perfil_columnas.sql | perfil por columna de d_perm_aws.user_desembolso para clasificar cualitativa/cuantitativa/identificador: filas totales, valores unicos (cardinalidad), nulos y rango. Numericos (cod_mes, mto_desembolso, flg_desembolso) y el codigo cod_tip_doc muestran rango de VALOR. Textos (key_value, desc_cliente, desc_campania, desc_producto) muestran rango de LONGITUD, no el contenido, para no sacar dato ni PII por el canal. Un solo escaneo de la tabla (CTE de agregados) reformado a una fila por columna con UNNEST multi-array. READ-ONLY
WITH m AS (
  SELECT
    count(*) AS n,
    count(DISTINCT cod_mes) AS d1,
    count(DISTINCT key_value) AS d2,
    count(DISTINCT cod_tip_doc) AS d3,
    count(DISTINCT mto_desembolso) AS d4,
    count(DISTINCT desc_cliente) AS d5,
    count(DISTINCT desc_campania) AS d6,
    count(DISTINCT desc_producto) AS d7,
    count(DISTINCT flg_desembolso) AS d8,
    sum(CASE WHEN cod_mes IS NULL THEN 1 ELSE 0 END) AS z1,
    sum(CASE WHEN key_value IS NULL THEN 1 ELSE 0 END) AS z2,
    sum(CASE WHEN cod_tip_doc IS NULL THEN 1 ELSE 0 END) AS z3,
    sum(CASE WHEN mto_desembolso IS NULL THEN 1 ELSE 0 END) AS z4,
    sum(CASE WHEN desc_cliente IS NULL THEN 1 ELSE 0 END) AS z5,
    sum(CASE WHEN desc_campania IS NULL THEN 1 ELSE 0 END) AS z6,
    sum(CASE WHEN desc_producto IS NULL THEN 1 ELSE 0 END) AS z7,
    sum(CASE WHEN flg_desembolso IS NULL THEN 1 ELSE 0 END) AS z8,
    concat(cast(min(cod_mes) AS varchar), '..', cast(max(cod_mes) AS varchar)) AS r1,
    concat(cast(min(length(key_value)) AS varchar), '..', cast(max(length(key_value)) AS varchar), ' chars') AS r2,
    concat(cast(min(cod_tip_doc) AS varchar), '..', cast(max(cod_tip_doc) AS varchar)) AS r3,
    concat(cast(round(min(cast(mto_desembolso AS double)), 2) AS varchar), '..', cast(round(max(cast(mto_desembolso AS double)), 2) AS varchar)) AS r4,
    concat(cast(min(length(desc_cliente)) AS varchar), '..', cast(max(length(desc_cliente)) AS varchar), ' chars') AS r5,
    concat(cast(min(length(desc_campania)) AS varchar), '..', cast(max(length(desc_campania)) AS varchar), ' chars') AS r6,
    concat(cast(min(length(desc_producto)) AS varchar), '..', cast(max(length(desc_producto)) AS varchar), ' chars') AS r7,
    concat(cast(min(flg_desembolso) AS varchar), '..', cast(max(flg_desembolso) AS varchar)) AS r8
  FROM d_perm_aws.user_desembolso
)
SELECT t.columna, m.n AS filas_totales, t.valores_unicos, t.nulos, t.rango
FROM m
CROSS JOIN UNNEST(
  ARRAY['cod_mes','key_value','cod_tip_doc','mto_desembolso','desc_cliente','desc_campania','desc_producto','flg_desembolso'],
  ARRAY[m.d1,m.d2,m.d3,m.d4,m.d5,m.d6,m.d7,m.d8],
  ARRAY[m.z1,m.z2,m.z3,m.z4,m.z5,m.z6,m.z7,m.z8],
  ARRAY[m.r1,m.r2,m.r3,m.r4,m.r5,m.r6,m.r7,m.r8]
) AS t(columna, valores_unicos, nulos, rango)
ORDER BY t.columna
