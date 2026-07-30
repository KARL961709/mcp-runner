-- u02 COBERTURA stock en 202606 (mes cerrado) -- escalera completa + variantes de join del censo
--     cen_por_key vs cen_por_key_tipdoc aisla si el tip_doc esta perdiendo matches
WITH p AS (SELECT DISTINCT cod_tip_doc AS tipdoc, key_value FROM e_perm_aws.scr_vcclibnk_rsk WHERE p_codmes = '202606'),
ren AS (SELECT key_value FROM e_perm_aws.t_mst_reniec_rsk
        WHERE tip_doc = '1' AND dis_ubi_domicilio IS NOT NULL GROUP BY key_value),
dcl AS (SELECT key_value FROM e_perm_aws.t_dim_cliente
        WHERE tipo_persona_host = '01' AND ubigeo_cd IS NOT NULL AND length(trim(ubigeo_cd)) = 6
        GROUP BY key_value),
cen AS (SELECT tip_doc, key_value,
               max(CASE WHEN latitud_y IS NOT NULL AND longitud_x IS NOT NULL THEN 1 ELSE 0 END) AS punto,
               max(CASE WHEN latitud_y BETWEEN -18.5 AND 0
                         AND longitud_x BETWEEN -81.5 AND -68.5 THEN 1 ELSE 0 END)               AS punto_peru,
               max(CASE WHEN id_mzna IS NOT NULL AND id_mzna <> 0 THEN 1 ELSE 0 END)             AS mzna
        FROM e_perm_aws.t_agg_censo_enrich_rsk GROUP BY tip_doc, key_value),
cenk AS (SELECT key_value, max(punto) AS punto, max(punto_peru) AS punto_peru, max(mzna) AS mzna
         FROM cen GROUP BY key_value),
api AS (SELECT key_value,
               max(CASE WHEN ubigeo IS NOT NULL AND length(trim(ubigeo)) = 6 THEN 1 ELSE 0 END) AS ubi,
               max(CASE WHEN manzana IS NOT NULL AND trim(manzana) <> '' THEN 1 ELSE 0 END)     AS mz,
               max(CASE WHEN lote IS NOT NULL AND trim(lote) <> '' THEN 1 ELSE 0 END)           AS lt
        FROM d_perm_aws.t_dmdireccion_apicliente GROUP BY key_value)
SELECT 'STK' AS poblacion, count(*) AS n,
       round(100.0 * avg(CASE WHEN r.key_value IS NOT NULL THEN 1 ELSE 0 END), 2)     AS reniec_dist,
       round(100.0 * avg(CASE WHEN d.key_value IS NOT NULL THEN 1 ELSE 0 END), 2)     AS dimcli_ubigeo,
       round(100.0 * avg(coalesce(ck.punto, 0)), 2)                                   AS cen_punto_por_key,
       round(100.0 * avg(coalesce(c2.punto, 0)), 2)                                   AS cen_punto_key_tipdoc,
       round(100.0 * avg(coalesce(ck.punto_peru, 0)), 2)                              AS cen_punto_en_peru,
       round(100.0 * avg(coalesce(ck.mzna, 0)), 2)                                    AS cen_manzana,
       round(100.0 * avg(coalesce(a.ubi, 0)), 2)                                      AS api_ubigeo,
       round(100.0 * avg(coalesce(a.mz, 0)), 2)                                       AS api_manzana,
       round(100.0 * avg(coalesce(a.lt, 0)), 2)                                       AS api_lote,
       round(100.0 * avg(CASE WHEN d.key_value IS NOT NULL OR r.key_value IS NOT NULL
                               OR coalesce(a.ubi, 0) = 1 THEN 1 ELSE 0 END), 2)        AS distrito_cualquiera,
       round(100.0 * avg(CASE WHEN coalesce(ck.mzna, 0) = 1
                              OR coalesce(a.mz, 0) = 1 THEN 1 ELSE 0 END), 2)          AS manzana_cualquiera
FROM p
LEFT JOIN ren r  ON r.key_value = p.key_value
LEFT JOIN dcl d  ON d.key_value = p.key_value
LEFT JOIN cenk ck ON ck.key_value = p.key_value
LEFT JOIN cen c2 ON c2.key_value = p.key_value AND c2.tip_doc = p.tipdoc
LEFT JOIN api a  ON a.key_value = p.key_value
