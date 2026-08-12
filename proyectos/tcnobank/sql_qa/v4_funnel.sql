-- v4_funnel.sql | G4. Funnel con el n AISLADO de cada filtro y su bad-rate, que es lo unico que permite firmar un
-- CASO: un filtro que saca poblacion con bad-rate menor al promedio esta sacando buenos y SUBE la LRA.
-- El n de cascada no sirve: medido dio entre 6 y 25 veces menos que el aislado.
SELECT f.filtro,
       sum(f.dispara)                                                                        AS n_aislado,
       round(100.0 * sum(f.dispara) / count(*), 4)                                           AS pct_universo,
       sum(CASE WHEN f.dispara = 1 AND c.target_12m_corr IS NOT NULL THEN 1 ELSE 0 END)      AS n_evaluable,
       sum(CASE WHEN f.dispara = 1 THEN coalesce(c.target_12m_corr, 0) ELSE 0 END)           AS n_malo,
       round(100.0 * sum(CASE WHEN f.dispara = 1 THEN coalesce(c.target_12m_corr, 0) ELSE 0 END)
             / nullif(sum(CASE WHEN f.dispara = 1 AND c.target_12m_corr IS NOT NULL THEN 1 ELSE 0 END), 0), 4)
                                                                                             AS bad_rate
FROM disc_model_owner.ds_adm_tcnb_cal c
CROSS JOIN UNNEST(
    ARRAY['01a.f_edad_rango','01b.f_edad_nomatch','02.f_banc_u12m','03.f_cast_ori','04.f_jud_ori',
          '05.f_ref_ori','06.f_ree_ori','07.f_malo_ori','08.f_cast_u24m','09.f_jud_u24m',
          '10.f_ref_u6m','11.f_mayor_cpp','12.f_gar_conv','13.f_fraude','14.f_entidades',
          '15.f_swap_u12m','19.f_swap_p12m','20.f_repro_p12m'],
    ARRAY[c.f_edad_rango, c.f_edad_nomatch, c.f_banc_u12m, c.f_cast_ori, c.f_jud_ori,
          c.f_ref_ori, c.f_ree_ori, c.f_malo_ori, c.f_cast_u24m, c.f_jud_u24m,
          c.f_ref_u6m, c.f_mayor_cpp, c.f_gar_conv, c.f_fraude, c.f_entidades,
          c.f_swap_u12m, c.f_swap_p12m, c.f_repro_p12m]) AS f (filtro, dispara)
GROUP BY f.filtro
ORDER BY n_aislado DESC
