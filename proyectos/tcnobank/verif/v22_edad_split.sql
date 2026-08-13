-- ============================================================================
-- V22. EL FILTRO DE EDAD PARTIDO EN MENOR DE 21 Y MAYOR DE 75
--   scan: cal U t_mst_reniec_rsk
--   ancla: edad k=0 contra codmes_mrm, la misma expresion de 60_filtros linea 61
--   el grupo que decide es el que dispara EDAD Y NADA MAS: es el unico que se mueve
--          si se libera el filtro. El resto del dirty sigue afuera por otro motivo
--   grupo 3 debe salir en cero por construccion: f_edad_rango lleva coalesce a 0, o sea
--          sin fecha no dispara. Si sale distinto de cero, el filtro no es lo que creemos
--   corte A entidad por grupo sobre la base de calibracion
--   corte B anio por grupo sobre toda la historia, para el salto de 2026
-- ============================================================================
WITH b AS (
    SELECT c.entidad,
           substr(c.codmes_mrm, 1, 4)                                                   AS anio,
           c.codmes_mrm,
           c.flg_clean,
           c.target_12m,
           c.f_edad_rango,
           c.f_cast_ori + c.f_jud_ori + c.f_ref_ori + c.f_ree_ori + c.f_malo_ori
         + c.f_cast_u24m + c.f_jud_u24m + c.f_ref_u6m + c.f_mayor_cpp + c.f_gar_conv
         + c.f_fraude + c.f_swap_u12m                                                   AS otros_12,
           date_diff('year', CAST(r.fec_nacimiento AS DATE),
                     CAST(date_parse(c.codmes_mrm || '01', '%Y%m%d') AS DATE))          AS edad
    FROM disc_model_owner.ds_adm_vcnbank_tc_cal c
    LEFT JOIN e_perm_aws.t_mst_reniec_rsk r
           ON r.tip_doc = c.tip_doc AND r.key_value = c.id_value
    WHERE c.flg_clean <> 99
),
g AS (
    SELECT entidad, anio, codmes_mrm, target_12m, edad,
           CASE WHEN flg_clean = 1                                       THEN '0.clean de referencia'
                WHEN f_edad_rango = 1 AND otros_12 = 0 AND edad < 21     THEN '1.solo edad menor de 21'
                WHEN f_edad_rango = 1 AND otros_12 = 0 AND edad > 75     THEN '2.solo edad mayor de 75'
                WHEN f_edad_rango = 1 AND otros_12 = 0                   THEN '3.solo edad sin fecha'
                WHEN f_edad_rango = 1                                    THEN '4.edad mas otro filtro'
                ELSE '5.dirty sin edad' END                                             AS grupo
    FROM b
)
SELECT 'A.entidad'                                                                      AS corte,
       entidad                                                                          AS dim,
       grupo,
       count(*)                                                                         AS n,
       count(target_12m)                                                                AS n_maduro,
       sum(target_12m)                                                                  AS n_malo,
       round(100.0 * avg(CAST(target_12m AS DOUBLE)), 4)                                AS rd_12m,
       min(edad)                                                                        AS edad_min,
       round(avg(CAST(edad AS DOUBLE)), 1)                                              AS edad_prom,
       max(edad)                                                                        AS edad_max
FROM g
WHERE codmes_mrm BETWEEN '202303' AND '202506'
GROUP BY entidad, grupo
UNION ALL
SELECT 'B.anio'                                                                         AS corte,
       anio                                                                             AS dim,
       grupo,
       count(*)                                                                         AS n,
       count(target_12m)                                                                AS n_maduro,
       sum(target_12m)                                                                  AS n_malo,
       round(100.0 * avg(CAST(target_12m AS DOUBLE)), 4)                                AS rd_12m,
       min(edad)                                                                        AS edad_min,
       round(avg(CAST(edad AS DOUBLE)), 1)                                              AS edad_prom,
       max(edad)                                                                        AS edad_max
FROM g
WHERE grupo IN ('1.solo edad menor de 21', '2.solo edad mayor de 75', '3.solo edad sin fecha')
GROUP BY anio, grupo
ORDER BY corte, dim, grupo
