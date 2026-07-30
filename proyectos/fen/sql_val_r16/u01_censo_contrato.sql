-- u01 AUDITORIA DEL CENSO -- nunca medi el formato de su key_value ni la validez de sus coordenadas
--     si el largo no calza con el del stock (64 chars segun b04), el join pierde gente en silencio
SELECT tip_doc,
       count(*)                                                        AS n_filas,
       count(DISTINCT key_value)                                       AS n_personas,
       min(length(trim(key_value)))                                    AS len_min,
       max(length(trim(key_value)))                                    AS len_max,
       sum(CASE WHEN latitud_y IS NULL OR longitud_x IS NULL THEN 1 ELSE 0 END)   AS sin_coord,
       sum(CASE WHEN latitud_y = 0 AND longitud_x = 0 THEN 1 ELSE 0 END)          AS coord_cero_cero,
       sum(CASE WHEN latitud_y BETWEEN -18.5 AND 0
                 AND longitud_x BETWEEN -81.5 AND -68.5 THEN 1 ELSE 0 END)        AS coord_en_peru,
       sum(CASE WHEN id_mzna IS NULL OR id_mzna = 0 THEN 1 ELSE 0 END)            AS sin_manzana
FROM e_perm_aws.t_agg_censo_enrich_rsk
GROUP BY tip_doc
ORDER BY 2 DESC
LIMIT 20
