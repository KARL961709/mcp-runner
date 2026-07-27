-- s02d_filtros_modelo_vs_calib.sql | que marca cada filtro en la ventana del slide, en el total y dentro de IBK
SELECT t.orden,
       t.filtro,
       t.trato,
       t.n_tot                                                 AS n_total_3m,
       round(100.0 * t.n_tot / nullif(a.base_tot, 0), 2)       AS pct_total,
       t.n_ibk                                                 AS n_ibk_3m,
       round(100.0 * t.n_ibk / nullif(a.base_ibk, 0), 2)       AS pct_ibk
FROM (
    SELECT count(1)                                      AS base_tot,
           sum(ibk)                                      AS base_ibk,
           sum(f_sunat)                                  AS t_sunat,      sum(ibk * f_sunat)  AS i_sunat,
           sum(f_esp)                                    AS t_esp,        sum(ibk * f_esp)    AS i_esp,
           sum(f_ind)                                    AS t_ind,        sum(ibk * f_ind)    AS i_ind,
           sum(f_mad)                                    AS t_mad,        sum(ibk * f_mad)    AS i_mad,
           sum(f_hon)                                    AS t_hon,        sum(ibk * f_hon)    AS i_hon,
           sum(f_est)                                    AS t_est,        sum(ibk * f_est)    AS i_est
    FROM (
        SELECT CASE WHEN entidad = 'IBK' THEN 1 ELSE 0 END AS ibk,
               CASE WHEN filtro_sunat_estado + filtro_sunat_giro + filtro_sunat_ubigeo > 0 THEN 1 ELSE 0 END AS f_sunat,
               filtro_especiales                                                                            AS f_esp,
               filtro_indeterminado                                                                         AS f_ind,
               filtro_madurez_blanda                                                                        AS f_mad,
               CASE WHEN filtro_castigado_org + filtro_judicial_org + filtro_reest_org + filtro_refin_org
                       + filtro_clasif_no_normal + filtro_diasatraso_org + filtro_sbs_no_normal_1um
                       + filtro_novig_1um + filtro_edad_titular + filtro_edad_rrll
                       + filtro_novig_12um + filtro_rrll_cast_12um > 0 THEN 1 ELSE 0 END                    AS f_hon,
               CASE WHEN filtro_perfil_empresa + filtro_deuda_comercial + filtro_ent_honrada
                       + filtro_excl_entidades + filtro_alta + filtro_monto_endeud + filtro_saldo_vig_m0
                       + filtro_pnsn + filtro_top4 + filtro_reactiva_puro
                       + filtro_impulsa_u12m + filtro_impulsa_m0 > 0 THEN 1 ELSE 0 END                      AS f_est
        FROM disc_model_owner.ds_adm_bpe_bankbn_cal
        WHERE CAST(codmes AS VARCHAR) IN ('202504','202505','202506')
          AND target_12m IS NOT NULL
    ) z
) a
CROSS JOIN UNNEST(
    ARRAY[1, 2, 3, 4, 5, 6],
    ARRAY['SUNAT estado/giro/ubigeo', 'Especiales (cruce)', 'Indeterminados 31-90d',
          'Madurez blanda', 'Malos en el origen', 'Scope del producto'],
    ARRAY['CASO1_LIBERA', 'CASO1_LIBERA', 'CASO1_LIBERA', 'CASO1_LIBERA', 'HONESTO_DIRTY', 'ESTRUCTURAL_99'],
    ARRAY[a.t_sunat, a.t_esp, a.t_ind, a.t_mad, a.t_hon, a.t_est],
    ARRAY[a.i_sunat, a.i_esp, a.i_ind, a.i_mad, a.i_hon, a.i_est]
) AS t (orden, filtro, trato, n_tot, n_ibk)
ORDER BY t.orden
