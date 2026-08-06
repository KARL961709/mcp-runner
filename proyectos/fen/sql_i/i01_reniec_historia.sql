-- 01 existe historia de domicilio o es un unico snapshot por persona
SELECT count(*) AS n_filas, count(DISTINCT key_value) AS n_personas,
       round(1.0*count(*)/count(DISTINCT key_value), 4) AS filas_por_persona,
       min(fec_dato) AS fec_dato_min, max(fec_dato) AS fec_dato_max,
       count(DISTINCT fec_dato) AS n_fechas
FROM e_perm_aws.t_mst_reniec_rsk
