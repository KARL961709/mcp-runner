-- 35_target.sql | las cuatro definiciones de target y la frontera de madurez.
-- ORDEN: el evento duro se evalua ANTES que la zona gris. Produccion lo hace al reves y por eso pierde 2,576 defaults
-- (medido con la q15 y la q26): un registro con castigo a futuro pero mora indeterminada sale etiquetado
-- INDETERMINADO y cae fuera del numerador Y del denominador. La PO del KAT ya usa el orden correcto, asi que esto
-- alinea con ella y no inventa criterio.
-- Las cuatro variantes se emiten juntas porque la decision no esta tomada:
--   target_12m       replica produccion: zona gris antes del evento, banda de indeterminado 9 a 60
--   target_12m_corr  evento antes de la zona gris                      medido: RD 10.37 a 10.75 por ciento
--   target_12m_b30   banda de indeterminado 30 a 60, como el KAT       medido: RD 10.37 a 9.89 por ciento
--   target_12m_full  las dos correcciones juntas
-- MADUREZ: falla_madurez marca los meses cuya ventana m+12 excede el ultimo mes del RCC (202606). Inmaduro es NULL,
-- nunca 0. La ventana de alta ya esta acotada a 202506 en 10_po, asi que la columna es el control, no el recorte.
CREATE TABLE disc_model_owner.ds_adm_tcnb_35_target
WITH (
    format              = 'PARQUET',
    parquet_compression = 'SNAPPY',
    partitioned_by      = ARRAY['codmes_mrm'],
    external_location   = '<S3_DATOS>/adm_tcnb_35_target/'
) AS
SELECT f.tip_doc,
       f.id_value,
       f.entidad,
       f.max_dm_fut,
       f.missing_12,
       CAST(CASE WHEN f.f_cast_fut = 1 OR f.f_jud_fut = 1
                   OR f.f_ref_fut = 1 OR f.f_ree_fut = 1 THEN 1 ELSE 0 END AS INTEGER)  AS f_evento_fut,
       CAST(CASE WHEN date_format(date_add('month', 12, date_parse(f.codmes_mrm, '%Y%m')), '%Y%m') > '202606'
                 THEN 1 ELSE 0 END AS INTEGER)                                          AS falla_madurez,
       CASE WHEN f.missing_12 = 12                                              THEN NULL
            WHEN f.missing_12 > 6                                               THEN NULL
            WHEN f.max_dm_fut BETWEEN 9 AND 60                                  THEN NULL
            WHEN f.max_dm_fut > 60                                              THEN 1
            WHEN f.f_cast_fut = 1 OR f.f_jud_fut = 1
              OR f.f_ref_fut  = 1 OR f.f_ree_fut = 1                            THEN 1
            ELSE 0 END                                                                  AS target_12m,
       CASE WHEN f.max_dm_fut > 60                                              THEN 1
            WHEN f.f_cast_fut = 1 OR f.f_jud_fut = 1
              OR f.f_ref_fut  = 1 OR f.f_ree_fut = 1                            THEN 1
            WHEN f.missing_12 = 12                                              THEN NULL
            WHEN f.missing_12 > 6                                               THEN NULL
            WHEN f.max_dm_fut BETWEEN 9 AND 60                                  THEN NULL
            ELSE 0 END                                                                  AS target_12m_corr,
       CASE WHEN f.missing_12 = 12                                              THEN NULL
            WHEN f.missing_12 > 6                                               THEN NULL
            WHEN f.max_dm_fut BETWEEN 30 AND 60                                 THEN NULL
            WHEN f.max_dm_fut > 60                                              THEN 1
            WHEN f.f_cast_fut = 1 OR f.f_jud_fut = 1
              OR f.f_ref_fut  = 1 OR f.f_ree_fut = 1                            THEN 1
            ELSE 0 END                                                                  AS target_12m_b30,
       CASE WHEN f.max_dm_fut > 60                                              THEN 1
            WHEN f.f_cast_fut = 1 OR f.f_jud_fut = 1
              OR f.f_ref_fut  = 1 OR f.f_ree_fut = 1                            THEN 1
            WHEN f.missing_12 = 12                                              THEN NULL
            WHEN f.missing_12 > 6                                               THEN NULL
            WHEN f.max_dm_fut BETWEEN 30 AND 60                                 THEN NULL
            ELSE 0 END                                                                  AS target_12m_full,
       f.codmes_mrm
FROM disc_model_owner.ds_adm_tcnb_30_fut f
