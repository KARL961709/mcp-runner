-- v10_delta_reanclaje.sql | G10. El delta que R11 exige para firmar el reanclaje de los cinco filtros de origen.
-- Compara la variante de produccion, que lee el RCC en el mes del alta, contra la reanclada a m-2, que es el ultimo
-- mes publicado cuando se decide. Sin este numero el CASO2 de esos cinco no se firma.
SELECT f.filtro,
       sum(f.m0)                                                               AS n_m0,
       sum(f.m2)                                                               AS n_m2,
       sum(f.m0) - sum(f.m2)                                                   AS delta,
       round(100.0 * (sum(f.m0) - sum(f.m2)) / nullif(sum(f.m0), 0), 3)        AS pct_que_pierde_el_reanclaje,
       count(*)                                                                AS n_magnitud
FROM disc_model_owner.ds_adm_tcnb_20_hist h
CROSS JOIN UNNEST(
    ARRAY['03.cast_ori','04.jud_ori','05.ref_ori','06.ree_ori','07.malo_ori'],
    ARRAY[h.f_cast_ori_m0, h.f_jud_ori_m0, h.f_ref_ori_m0, h.f_ree_ori_m0, h.f_malo_ori_m0],
    ARRAY[h.f_cast_ori_m2, h.f_jud_ori_m2, h.f_ref_ori_m2, h.f_ree_ori_m2, h.f_malo_ori_m2])
     AS f (filtro, m0, m2)
GROUP BY f.filtro
ORDER BY f.filtro
