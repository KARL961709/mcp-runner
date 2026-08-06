-- g02 Cobertura de cada fuente de ubigeo sobre el STOCK, y cuánto coinciden entre sí.
-- Agregado puro: ni un identificador de cliente. 1 fila.
-- Si g01 dice que t_mst_ubigeos_rsk no existe, comentar el bloque U y correr igual.
WITH pob AS (
  SELECT DISTINCT key_value
  FROM e_perm_aws.scr_vcclibnk_rsk
  WHERE cod_mes = '202607'
),
dim AS (
  SELECT key_value, MAX(ubigeo_cd) AS ubigeo
  FROM e_perm_aws.t_dim_cliente
  WHERE ubigeo_cd IS NOT NULL AND ubigeo_cd <> ''
  GROUP BY key_value
),
u AS (
  SELECT coddoc AS key_value, MAX(ubigeofinal) AS ubigeo
  FROM e_perm_aws.t_mst_ubigeos_rsk
  WHERE ubigeofinal IS NOT NULL AND ubigeofinal <> ''
  GROUP BY coddoc
)
SELECT count(*)                                                       AS n_stock,
       count(d.ubigeo)                                                AS con_t_dim_cliente,
       count(u.ubigeo)                                                AS con_t_mst_ubigeos,
       count(CASE WHEN d.ubigeo IS NOT NULL AND u.ubigeo IS NOT NULL THEN 1 END) AS en_ambas,
       count(CASE WHEN d.ubigeo = u.ubigeo THEN 1 END)                AS coinciden,
       count(CASE WHEN d.ubigeo IS NOT NULL AND u.ubigeo IS NOT NULL
                   AND d.ubigeo <> u.ubigeo THEN 1 END)               AS discrepan,
       count(CASE WHEN d.ubigeo IS NULL AND u.ubigeo IS NULL THEN 1 END) AS sin_ninguna
FROM pob p
LEFT JOIN dim d ON p.key_value = d.key_value
LEFT JOIN u   ON p.key_value = u.key_value
