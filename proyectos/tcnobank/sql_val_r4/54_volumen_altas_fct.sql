-- 54_volumen_altas_fct.sql | perfil anual de t_rsk_fct_altas_tc apoyandose solo en p_codmes, sin asumir ningun otro nombre de columna. Sirve para contrastar su volumen contra tng_altas aunque el resto del esquema todavia no se conozca
SELECT substr(p_codmes, 1, 4)      AS anio,
       count(*)                    AS n_filas,
       count(DISTINCT p_codmes)    AS meses,
       min(p_codmes)               AS codmes_min,
       max(p_codmes)               AS codmes_max
FROM e_perm_aws.t_rsk_fct_altas_tc
GROUP BY substr(p_codmes, 1, 4)
ORDER BY anio
