-- g03 CONTRATO FISICO de t_dim_cliente -- grano real y formato de ubigeo_cd
--     produccion dedupea por (tip_doc, key_value) ordenando por fecha_creacion -> aca se MIDE el fan-out
SELECT tipo_persona_host,
       count(*)                                                              AS n_filas,
       count(DISTINCT key_value)                                             AS n_key,
       count(DISTINCT trim(ubigeo_cd))                                       AS n_ubigeos_distintos,
       min(length(trim(ubigeo_cd)))                                          AS ub_len_min,
       max(length(trim(ubigeo_cd)))                                          AS ub_len_max,
       sum(CASE WHEN ubigeo_cd IS NULL OR trim(ubigeo_cd) = '' THEN 1 ELSE 0 END) AS ub_vacio
FROM e_perm_aws.t_dim_cliente
GROUP BY tipo_persona_host
ORDER BY 2 DESC
LIMIT 20
