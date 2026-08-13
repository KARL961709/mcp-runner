-- ============================================================================
-- 85. NODO - COBERTURA DE LOS INSUMOS Y REPARTO
--   scan: ds_adm_vcnbank_tc_cal en [202303,202506]
--   ancla: el csv de nodos da 23.2 / 27.0 / 49.8 sobre IBK con rd 4.18 / 6.04 / 9.80.
--          Fuera de IBK el nodo debe ser SIN_ALCANCE y nunca N1 N2 ni N3: si aparece
--          un nodo fuera de la entidad 00002 es que se calculo sobre ausencia de dato
-- ============================================================================
SELECT entidad,
       nodo_final,
       count(*)                                                                         AS n,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY entidad), 3)           AS pct_entidad,
       round(100.0 * avg(CAST(target_12m AS DOUBLE)), 4)                                AS rd_12m,
       round(100.0 * avg(CAST(flg_plinero_u3m AS DOUBLE)), 3)                           AS pct_plinero,
       round(100.0 * avg(CAST(flag_pasivos_afp_f AS DOUBLE)), 3)                        AS pct_pasivo,
       round(100.0 * avg(CAST(flg_cs_v2 AS DOUBLE)), 3)                                 AS pct_cs,
       round(100.0 * avg(CAST(ctrl_sin_360 AS DOUBLE)), 3)                              AS pct_sin_360,
       round(100.0 * avg(CAST(ctrl_sin_cta_sueldo AS DOUBLE)), 3)                       AS pct_sin_cs,
       round(100.0 * avg(CAST(ctrl_sin_plin AS DOUBLE)), 3)                             AS pct_sin_plin
FROM disc_model_owner.ds_adm_vcnbank_tc_cal
WHERE flg_calib = 1 AND flg_clean = 1
  AND codmes_mrm BETWEEN '202303' AND '202506'
GROUP BY entidad, nodo_final
ORDER BY entidad, nodo_final
LIMIT 40
