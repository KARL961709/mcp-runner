-- a01 QUE COPIA DEL GRADO SOBREVIVE -- filas por cada candidata
SELECT 'd_perm.grado_elnino_ubigeo_v3'      AS tabla, count(*) AS n FROM d_perm_aws.grado_elnino_ubigeo_v3
UNION ALL SELECT 'dmo.grado_elnino_ubigeo_v3',      count(*) FROM disc_model_owner.grado_elnino_ubigeo_v3
UNION ALL SELECT 'dmo.grado_elnino_lookup_v3',      count(*) FROM disc_model_owner.grado_elnino_lookup_v3
UNION ALL SELECT 'dmo.grado_elnino_ubigeo_v2',      count(*) FROM disc_model_owner.grado_elnino_ubigeo_v2
UNION ALL SELECT 'dmo.grado_elnino_ubigeo',         count(*) FROM disc_model_owner.grado_elnino_ubigeo
UNION ALL SELECT 'dmo.reniec_cod_grado_v3',         count(*) FROM disc_model_owner.reniec_cod_grado_v3
UNION ALL SELECT 'dmo.reniec_cod_grado',            count(*) FROM disc_model_owner.reniec_cod_grado
ORDER BY 2 DESC
