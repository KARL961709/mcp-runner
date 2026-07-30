-- f04 FAN-OUT de la lookup del join oficial por NOMBRE (dep+prov+dist)
SELECT count(*)                                                   AS n_filas,
       count(DISTINCT cod_ubigeo)                                 AS n_ubigeo,
       count(DISTINCT concat_ws('|', dep, prov, dist))            AS n_llaves_nombre,
       count(*) - count(DISTINCT concat_ws('|', dep, prov, dist)) AS exceso_fanout,
       sum(CASE WHEN origen = 'alias' THEN 1 ELSE 0 END)          AS n_alias,
       sum(CASE WHEN dep IS NULL OR prov IS NULL OR dist IS NULL
                  OR dep = '' OR prov = '' OR dist = '' THEN 1 ELSE 0 END) AS n_llave_vacia
FROM disc_model_owner.grado_elnino_lookup_v3
