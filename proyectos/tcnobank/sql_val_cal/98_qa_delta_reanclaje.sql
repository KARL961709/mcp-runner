-- ============================================================================
-- 98. DELTA DEL REANCLAJE M0 CONTRA M2 EN LOS CINCO FILTROS DE ORIGEN
--   malo_ori viaja invertido a proposito: el vigente es m0 y el contrafactual es m2
-- ============================================================================
SELECT f.filtro,
       sum(f.m0)                                                                       AS n_m0,
       sum(f.m2)                                                                       AS n_m2,
       sum(f.m0) - sum(f.m2)                                                           AS delta,
       round(100.0 * (sum(f.m0) - sum(f.m2)) / nullif(sum(f.m0), 0), 3)                AS pct_pierde_reanclaje,
       count(*)                                                                        AS n_magnitud
FROM disc_model_owner.ds_adm_vcnbank_tc_cal c
CROSS JOIN UNNEST(
    ARRAY['cast_ori','jud_ori','ref_ori','ree_ori','malo_ori'],
    ARRAY[c.ctrl_cast_ori_m0, c.ctrl_jud_ori_m0, c.ctrl_ref_ori_m0, c.ctrl_ree_ori_m0, c.f_malo_ori],
    ARRAY[c.f_cast_ori, c.f_jud_ori, c.f_ref_ori, c.f_ree_ori, c.ctrl_malo_ori_m2])
     AS f (filtro, m0, m2)
GROUP BY f.filtro
ORDER BY f.filtro
