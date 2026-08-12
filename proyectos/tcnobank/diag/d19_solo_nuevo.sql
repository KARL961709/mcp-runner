-- ============================================================================
-- D19. DE QUE ESTA HECHO EL SOLO_NUEVO DEL 87
--   scan: cal U ds_flg_admtcnobk1_rsk [202303,202512], ventana madura
--   ancla: 87 recorta el lado nuevo a flg_clean <> 99 y el vigente a BUENO o MALO. Un
--          registro que la vigente etiqueta EDAD existe en las dos tablas pero cae en
--          solo_nuevo. Lo unico que seria poblacion de mas es la fila que NO esta en la
--          vigente. 88 no sirve para esto: no recorta los 99
-- ============================================================================
WITH nuevo AS (
    SELECT codmes_mrm, tip_doc, id_value, flg_clean, target_12m
    FROM disc_model_owner.ds_adm_vcnbank_tc_cal
    WHERE prelacion_cod = 1
      AND flg_clean <> 99
      AND codmes_mrm BETWEEN '202303' AND '202512'
),
vigente AS (
    SELECT codmes_mrm, tip_doc, id_value, dsc_flg_malo_12m
    FROM e_perm_aws.ds_flg_admtcnobk1_rsk
    WHERE prelacion_00m = 1
      AND codmes_mrm BETWEEN '202303' AND '202512'
)
SELECT coalesce(v.dsc_flg_malo_12m, 'NO ESTA EN LA VIGENTE')                            AS etiqueta_vigente,
       count(*)                                                                         AS n,
       round(100.0 * count(*) / sum(count(*)) OVER (), 3)                                AS pct_del_solo_nuevo,
       sum(CASE WHEN n.flg_clean = 1 THEN 1 ELSE 0 END)                                  AS n_clean,
       sum(CASE WHEN n.flg_clean = 0 THEN 1 ELSE 0 END)                                  AS n_dirty,
       round(100.0 * avg(CAST(n.target_12m AS DOUBLE)), 4)                               AS rd_12m
FROM nuevo n
LEFT JOIN vigente v
       ON v.codmes_mrm = n.codmes_mrm AND v.tip_doc = n.tip_doc AND v.id_value = n.id_value
WHERE v.dsc_flg_malo_12m IS NULL
   OR v.dsc_flg_malo_12m NOT IN ('BUENO','MALO')
GROUP BY coalesce(v.dsc_flg_malo_12m, 'NO ESTA EN LA VIGENTE')
ORDER BY n DESC
LIMIT 40
