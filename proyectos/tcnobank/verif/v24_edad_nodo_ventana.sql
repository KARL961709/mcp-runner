-- ============================================================================
-- V24. EL TRAMO JOVEN POR NODO Y POR VENTANA - CIERRA LA CONTRADICCION DE V22
--   scan: cal U t_mst_reniec_rsk
--   v22 dejo dos lecturas legitimas y opuestas del mismo grupo en IBK
--          historia 2019-2026     joven 16.36 contra clean 13.33   MAS riesgo
--          base calibracion       joven  8.16 contra clean 10.54   MENOS riesgo
--          las dos maduras. Corte D de v22 no llevaba filtro de ventana, ese fue el hueco
--   corte A el mismo corte por nodo, ahora partido en tres ventanas. Si dentro de la base
--          de calibracion el joven sigue MAS riesgoso en los tres nodos, la vuelta del
--          agregado es composicion y el filtro se queda como esta. Si se da vuelta tambien
--          por nodo, es comportamiento y hay que decidir con la ventana que se va a usar
--   corte B edad exacta con date_diff, que el control de semantica de v22 probo correcto.
--          v22 bucketeo con una correccion mia que resulto falsa, asi que su corte C esta
--          corrido hasta en un ano y no se puede leer. Menor de 18 no es exclusion de
--          politica sino dato roto: no puede haber titular de tarjeta
--   corte C el mismo joven por anio y nodo en IBK, para ver si la mejora es de todos los
--          nodos o de uno solo, y si coincide con el escalon de 202411
--   la ventana 3 arranca en 202412 porque ahi cierra el cambio de regimen ya medido
-- ============================================================================
WITH b AS (
    SELECT c.entidad,
           c.codmes_mrm,
           substr(c.codmes_mrm, 1, 4)                                                   AS anio,
           coalesce(c.nodo_final, 'SIN_NODO')                                           AS nodo,
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
    SELECT entidad, codmes_mrm, anio, nodo, target_12m, edad,
           CASE WHEN flg_clean = 1                                       THEN '0.clean'
                WHEN f_edad_rango = 1 AND otros_12 = 0 AND edad < 21     THEN '1.menor de 21'
                WHEN f_edad_rango = 1 AND otros_12 = 0                   THEN '2.mayor de 75'
                ELSE '3.otro dirty' END                                                 AS grupo
    FROM b
),
v AS (
    SELECT g.*, w AS ventana
    FROM g
    CROSS JOIN UNNEST(ARRAY['1.historia 201902-202606',
                            '2.base calib 202303-202506',
                            '3.post escalon 202412-202506']) AS t (w)
    WHERE (w = '1.historia 201902-202606')
       OR (w = '2.base calib 202303-202506'    AND codmes_mrm BETWEEN '202303' AND '202506')
       OR (w = '3.post escalon 202412-202506'  AND codmes_mrm BETWEEN '202412' AND '202506')
)
SELECT 'A.nodo x ventana'                                                               AS corte,
       ventana                                                                          AS dim,
       nodo || ' ' || grupo                                                             AS detalle,
       count(*)                                                                         AS n,
       count(target_12m)                                                                AS n_maduro,
       sum(target_12m)                                                                  AS n_malo,
       round(100.0 * avg(CAST(target_12m AS DOUBLE)), 4)                                AS rd_12m,
       min(edad)                                                                        AS edad_min,
       max(edad)                                                                        AS edad_max
FROM v
WHERE entidad = '00002' AND grupo IN ('0.clean', '1.menor de 21')
GROUP BY ventana, nodo || ' ' || grupo
UNION ALL
SELECT 'B.edad exacta'                                                                  AS corte,
       entidad                                                                          AS dim,
       CASE WHEN edad < 18 THEN '1.menor de 18 dato roto'
            ELSE '2.edad ' || CAST(edad AS VARCHAR) END                                 AS detalle,
       count(*)                                                                         AS n,
       count(target_12m)                                                                AS n_maduro,
       sum(target_12m)                                                                  AS n_malo,
       round(100.0 * avg(CAST(target_12m AS DOUBLE)), 4)                                AS rd_12m,
       min(edad)                                                                        AS edad_min,
       max(edad)                                                                        AS edad_max
FROM g
WHERE grupo = '1.menor de 21' AND codmes_mrm BETWEEN '202303' AND '202506'
GROUP BY entidad,
         CASE WHEN edad < 18 THEN '1.menor de 18 dato roto'
              ELSE '2.edad ' || CAST(edad AS VARCHAR) END
UNION ALL
SELECT 'C.anio x nodo ibk'                                                              AS corte,
       anio                                                                             AS dim,
       nodo || ' ' || grupo                                                             AS detalle,
       count(*)                                                                         AS n,
       count(target_12m)                                                                AS n_maduro,
       sum(target_12m)                                                                  AS n_malo,
       round(100.0 * avg(CAST(target_12m AS DOUBLE)), 4)                                AS rd_12m,
       min(edad)                                                                        AS edad_min,
       max(edad)                                                                        AS edad_max
FROM g
WHERE entidad = '00002' AND grupo IN ('0.clean', '1.menor de 21') AND anio >= '2022'
GROUP BY anio, nodo || ' ' || grupo
ORDER BY corte, dim, detalle
