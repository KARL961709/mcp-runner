-- ============================================================================
-- 94. FUNNEL AISLADO CON BAD-RATE POR FILTRO
-- ============================================================================
SELECT f.filtro,
       sum(f.dispara)                                                                  AS n_aislado,
       round(100.0 * sum(f.dispara) / count(*), 4)                                     AS pct_universo,
       sum(CASE WHEN f.dispara = 1 AND c.target_12m IS NOT NULL THEN 1 ELSE 0 END)     AS n_evaluable,
       sum(CASE WHEN f.dispara = 1 THEN coalesce(c.target_12m, 0) ELSE 0 END)          AS n_malo,
       round(100.0 * sum(CASE WHEN f.dispara = 1 THEN coalesce(c.target_12m, 0) ELSE 0 END)
             / nullif(sum(CASE WHEN f.dispara = 1 AND c.target_12m IS NOT NULL THEN 1 ELSE 0 END), 0), 4)
                                                                                       AS bad_rate
FROM disc_model_owner.ds_adm_vcnbank_tc_cal c
CROSS JOIN UNNEST(
    ARRAY['f_edad_rango', 'f_edad_nomatch', 'f_banc_u12m', 'f_cast_ori', 'f_jud_ori', 'f_ref_ori', 'f_ree_ori', 'f_malo_ori', 'f_cast_u24m', 'f_jud_u24m', 'f_ref_u6m', 'f_mayor_cpp', 'f_gar_conv', 'f_fraude', 'f_entidades', 'f_swap_u12m', 'f_swap_p12m', 'f_repro_p12m'],
    ARRAY[c.f_edad_rango, c.f_edad_nomatch, c.f_banc_u12m, c.f_cast_ori, c.f_jud_ori, c.f_ref_ori, c.f_ree_ori, c.f_malo_ori, c.f_cast_u24m, c.f_jud_u24m, c.f_ref_u6m, c.f_mayor_cpp, c.f_gar_conv, c.f_fraude, c.f_entidades, c.f_swap_u12m, c.f_swap_p12m, c.f_repro_p12m]) AS f (filtro, dispara)
GROUP BY f.filtro
ORDER BY n_aislado DESC
