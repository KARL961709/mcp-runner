-- s02e_estructurales_ibk.sql | cuanto saca cada filtro estructural en IBK: la ventana del slide y la de calibracion
SELECT t.orden,
       t.filtro,
       t.n_slide                                                  AS n_202504_202506,
       round(100.0 * t.n_slide / nullif(a.base_slide, 0), 2)      AS pct_slide,
       t.n_cal                                                    AS n_202206_202506,
       round(100.0 * t.n_cal / nullif(a.base_cal, 0), 2)          AS pct_cal
FROM (
    SELECT sum(sl) AS base_slide, count(1) AS base_cal,
           sum(sl * f_pe) AS s1, sum(f_pe) AS c1,   sum(sl * f_dc) AS s2, sum(f_dc) AS c2,
           sum(sl * f_eh) AS s3, sum(f_eh) AS c3,   sum(sl * f_ex) AS s4, sum(f_ex) AS c4,
           sum(sl * f_al) AS s5, sum(f_al) AS c5,   sum(sl * f_me) AS s6, sum(f_me) AS c6,
           sum(sl * f_sv) AS s7, sum(f_sv) AS c7,   sum(sl * f_pn) AS s8, sum(f_pn) AS c8,
           sum(sl * f_t4) AS s9, sum(f_t4) AS c9,   sum(sl * f_rp) AS s10, sum(f_rp) AS c10,
           sum(sl * f_iu) AS s11, sum(f_iu) AS c11, sum(sl * f_im) AS s12, sum(f_im) AS c12
    FROM (
        SELECT CASE WHEN CAST(codmes AS VARCHAR) IN ('202504','202505','202506') THEN 1 ELSE 0 END AS sl,
               filtro_perfil_empresa AS f_pe, filtro_deuda_comercial AS f_dc,
               filtro_ent_honrada    AS f_eh, filtro_excl_entidades  AS f_ex,
               filtro_alta           AS f_al, filtro_monto_endeud    AS f_me,
               filtro_saldo_vig_m0   AS f_sv, filtro_pnsn            AS f_pn,
               filtro_top4           AS f_t4, filtro_reactiva_puro   AS f_rp,
               filtro_impulsa_u12m   AS f_iu, filtro_impulsa_m0      AS f_im
        FROM disc_model_owner.ds_adm_bpe_bankbn_cal
        WHERE CAST(codmes AS VARCHAR) BETWEEN '202206' AND '202506'
          AND entidad = 'IBK'
          AND target_12m IS NOT NULL
    ) z
) a
CROSS JOIN UNNEST(
    ARRAY[1,2,3,4,5,6,7,8,9,10,11,12],
    ARRAY['perfil_empresa','deuda_comercial','ent_honrada','excl_entidades','alta','monto_endeud',
          'saldo_vig_m0','pnsn','top4','REACTIVA_PURO','IMPULSA_u12m','IMPULSA_m0'],
    ARRAY[a.s1,a.s2,a.s3,a.s4,a.s5,a.s6,a.s7,a.s8,a.s9,a.s10,a.s11,a.s12],
    ARRAY[a.c1,a.c2,a.c3,a.c4,a.c5,a.c6,a.c7,a.c8,a.c9,a.c10,a.c11,a.c12]
) AS t (orden, filtro, n_slide, n_cal)
ORDER BY t.orden
