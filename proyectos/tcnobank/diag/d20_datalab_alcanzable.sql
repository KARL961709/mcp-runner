-- ============================================================================
-- D20. SE ALCANZA DATALAB Y ESTA LA TABLA DE NODOS YA CONSTRUIDA
--   scan: metadato, no datos
--   ancla: si el esquema no es accesible la query FALLA, y ese fallo es la respuesta.
--          Si responde y lista t_edc_sd_bd_app_tc_nobank_vf_1/2/3, no hay que
--          reproducir las 3,576 lineas de la logica de nodos: se lee directo
-- ============================================================================
SHOW TABLES IN datalab_risk_people_banking '*tc_nobank*'
