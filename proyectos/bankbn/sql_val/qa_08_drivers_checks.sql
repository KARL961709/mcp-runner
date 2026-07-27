-- qa_08_drivers_checks.sql | drivers: impulsa vivo a los dos lados del corte d_perm e_perm, reactiva material 2020-2022, tip_doc ppjj, edad y fec_nacimiento | n_viol tiene que ser 0 en TODAS las filas, n_magnitud es el numero que se reporta
WITH a AS (
    SELECT
        CAST(count(1) AS BIGINT) AS n_filas,
        CAST(count(DISTINCT CAST(codmes AS VARCHAR)) AS BIGINT) AS n_meses,
        min(CAST(codmes AS VARCHAR)) AS mes_min,
        max(CAST(codmes AS VARCHAR)) AS mes_max,
        CAST(sum(falla_sin_entidad) AS BIGINT) AS v_ent,
        CAST(sum(falla_sin_tip_doc) AS BIGINT) AS v_tipdoc,
        CAST(sum(falla_sin_segmento_reactiva) AS BIGINT) AS v_seg,
        CAST(sum(CASE WHEN flg_ppjj <> (CASE WHEN CAST(tip_doc AS VARCHAR) = '2' THEN 1 ELSE 0 END) THEN 1 ELSE 0 END) AS BIGINT) AS v_diag,
        CAST(sum(CASE WHEN tip_doc IS NULL OR CAST(tip_doc AS VARCHAR) <> trim(CAST(tip_doc AS VARCHAR)) OR length(trim(CAST(tip_doc AS VARCHAR))) <> 1 THEN 1 ELSE 0 END) AS BIGINT) AS v_fmt,
        CAST(sum(CASE WHEN segmento_reactiva IS DISTINCT FROM (CASE WHEN flg_reactiva = 0 AND flg_solo_reactiva = 0 THEN 'SOLO NEGOCIO'
                                                                   WHEN flg_reactiva = 1 AND flg_solo_reactiva = 0 THEN 'MIXTO'
                                                                   WHEN flg_reactiva = 1 AND flg_solo_reactiva = 1 THEN 'REACTIVA'
                                                                   ELSE 'SIN DEUDA' END) THEN 1 ELSE 0 END) AS BIGINT) AS v_segmap,
        CAST(sum(flg_impulsa) AS BIGINT) AS o_imp_m0,
        CAST(sum(flg_impulsa_u12m) AS BIGINT) AS o_imp_u12,
        CAST(sum(CASE WHEN CAST(codmes AS VARCHAR) <= '201812' THEN 1 ELSE 0 END) AS BIGINT) AS o_n_pre2019,
        CAST(sum(CASE WHEN CAST(codmes AS VARCHAR) <= '201812' AND flg_impulsa = 1 THEN 1 ELSE 0 END) AS BIGINT) AS o_imp_pre2019,
        CAST(sum(CASE WHEN CAST(codmes AS VARCHAR) >= '201901' AND flg_impulsa = 1 THEN 1 ELSE 0 END) AS BIGINT) AS o_imp_post2019,
        CAST(sum(CASE WHEN sld_impulsa_m0 IS NOT NULL THEN 1 ELSE 0 END) AS BIGINT) AS o_sld_m0_nn,
        CAST(sum(CASE WHEN substr(CAST(codmes AS VARCHAR), 1, 4) IN ('2020','2021','2022') AND segmento_reactiva IN ('REACTIVA','MIXTO') THEN 1 ELSE 0 END) AS BIGINT) AS o_react_covid,
        CAST(sum(CASE WHEN substr(CAST(codmes AS VARCHAR), 1, 4) IN ('2018','2019') AND segmento_reactiva IN ('REACTIVA','MIXTO') THEN 1 ELSE 0 END) AS BIGINT) AS o_react_pre,
        CAST(sum(CASE WHEN substr(CAST(codmes AS VARCHAR), 1, 4) IN ('2020','2021','2022') THEN 1 ELSE 0 END) AS BIGINT) AS o_n_covid,
        CAST(sum(CASE WHEN substr(CAST(codmes AS VARCHAR), 1, 4) IN ('2018','2019') THEN 1 ELSE 0 END) AS BIGINT) AS o_n_pre,
        CAST(sum(CASE WHEN segmento_reactiva = 'REACTIVA' THEN 1 ELSE 0 END) AS BIGINT) AS o_react_puro,
        CAST(sum(CASE WHEN CAST(tip_doc AS VARCHAR) <> '2' THEN 1 ELSE 0 END) AS BIGINT) AS o_n_ppnn,
        CAST(sum(CASE WHEN CAST(tip_doc AS VARCHAR) <> '2' AND fec_nacimiento IS NULL THEN 1 ELSE 0 END) AS BIGINT) AS o_ppnn_sinfn,
        CAST(sum(CASE WHEN CAST(tip_doc AS VARCHAR) = '2' THEN 1 ELSE 0 END) AS BIGINT) AS o_n_ppjj,
        CAST(sum(CASE WHEN CAST(tip_doc AS VARCHAR) = '2' AND fec_nacimiento IS NOT NULL THEN 1 ELSE 0 END) AS BIGINT) AS o_ppjj_confn,
        CAST(sum(CASE WHEN CAST(tip_doc AS VARCHAR) = '2' AND fec_nacimiento_rl_max IS NULL THEN 1 ELSE 0 END) AS BIGINT) AS o_ppjj_sinrl,
        CAST(sum(CASE WHEN falla_impulsa_u12m_inmaduro = 1 AND date_format(date_parse(CAST(codmes AS VARCHAR), '%Y%m') + interval '12' month, '%Y%m') <= '202606' THEN 1 ELSE 0 END) AS BIGINT) AS v_u12inm,
        CAST(sum(CASE WHEN falla_codmes_fuera_ventana <> (CASE WHEN CAST(codmes AS VARCHAR) NOT BETWEEN '202206' AND '202506' THEN 1 ELSE 0 END) THEN 1 ELSE 0 END) AS BIGINT) AS v_ventana,
        CAST(sum(CASE WHEN falla_codmes_fuera_ventana = 0 THEN 1 ELSE 0 END) AS BIGINT) AS o_en_ventana,
        CAST(count(DISTINCT CASE WHEN falla_codmes_fuera_ventana = 0 THEN CAST(codmes AS VARCHAR) END) AS BIGINT) AS o_meses_ventana,
        CAST(count(DISTINCT CAST(tip_doc AS VARCHAR)) AS BIGINT) AS o_n_tipdoc
    FROM disc_model_owner.ds_adm_bpe_bankbn_drivers
)
SELECT
    t.orden,
    t.chk,
    t.n_viol,
    t.n_magnitud,
    round(100e0 * t.n_magnitud / nullif(t.n_base, 0), 4) AS pct_sobre_base,
    t.n_base,
    CASE WHEN t.n_viol = 0 THEN 'OK' ELSE 'REVISAR' END AS veredicto,
    a.n_filas,
    a.n_meses,
    a.mes_min,
    a.mes_max,
    a.o_n_tipdoc,
    a.o_meses_ventana
FROM a
CROSS JOIN UNNEST(ARRAY[
    ROW(1, 'D01 falla_sin_entidad', a.v_ent, a.v_ent, a.n_filas),
    ROW(2, 'D02 falla_sin_tip_doc', a.v_tipdoc, a.v_tipdoc, a.n_filas),
    ROW(3, 'D03 falla_sin_segmento_reactiva', a.v_seg, a.v_seg, a.n_filas),
    ROW(4, 'D04 flg_ppjj no equivale a tip_doc igual 2', a.v_diag, a.v_diag, a.n_filas),
    ROW(5, 'D05 tip_doc con formato no canonico ceros o espacios', a.v_fmt, a.v_fmt, a.n_filas),
    ROW(6, 'D06 segmento_reactiva no coincide con el par de flags', a.v_segmap, a.v_segmap, a.n_filas),
    ROW(7, 'D07 impulsa m0 muerto en toda la tabla', CAST(CASE WHEN a.o_imp_m0 = 0 THEN 1 ELSE 0 END AS BIGINT), a.o_imp_m0, a.n_filas),
    ROW(8, 'D08 impulsa m0 muerto en la rama d_perm codmes menor igual 201812', CAST(CASE WHEN a.o_n_pre2019 > 0 AND a.o_imp_pre2019 = 0 AND a.o_imp_post2019 > 0 THEN 1 ELSE 0 END AS BIGINT), a.o_imp_pre2019, a.o_n_pre2019),
    ROW(9, 'D09 OBS impulsa m0 en la rama e_perm codmes mayor igual 201901', CAST(0 AS BIGINT), a.o_imp_post2019, a.n_filas - a.o_n_pre2019),
    ROW(10, 'D10 OBS impulsa u12m total', CAST(0 AS BIGINT), a.o_imp_u12, a.n_filas),
    ROW(11, 'D11 OBS filas con sld_impulsa_m0 no nulo join vivo', CAST(CASE WHEN a.o_sld_m0_nn = 0 THEN 1 ELSE 0 END AS BIGINT), a.o_sld_m0_nn, a.n_filas),
    ROW(12, 'D12 reactiva mas mixto sin masa en 2020-2022', CAST(CASE WHEN a.o_n_covid > 0 AND a.o_react_covid = 0 THEN 1 ELSE 0 END AS BIGINT), a.o_react_covid, a.o_n_covid),
    ROW(13, 'D13 OBS reactiva mas mixto en 2018-2019 debe ser marginal', CAST(0 AS BIGINT), a.o_react_pre, a.o_n_pre),
    ROW(14, 'D14 OBS reactiva puro total', CAST(0 AS BIGINT), a.o_react_puro, a.n_filas),
    ROW(15, 'D15 fec_nacimiento NULL en personas naturales mas de la mitad', CAST(CASE WHEN a.o_n_ppnn > 0 AND a.o_ppnn_sinfn * 2 >= a.o_n_ppnn THEN 1 ELSE 0 END AS BIGINT), a.o_ppnn_sinfn, a.o_n_ppnn),
    ROW(16, 'D16 fec_nacimiento presente en PPJJ imposible por diseno', a.o_ppjj_confn, a.o_ppjj_confn, a.o_n_ppjj),
    ROW(17, 'D17 fec_nacimiento_rl_max NULL en PPJJ mas de la mitad', CAST(CASE WHEN a.o_n_ppjj > 0 AND a.o_ppjj_sinrl * 2 >= a.o_n_ppjj THEN 1 ELSE 0 END AS BIGINT), a.o_ppjj_sinrl, a.o_n_ppjj),
    ROW(18, 'D18 falla_impulsa_u12m_inmaduro prendido en mes maduro', a.v_u12inm, a.v_u12inm, a.n_filas),
    ROW(19, 'D19 falla_codmes_fuera_ventana no responde a 202206 202506', a.v_ventana, a.v_ventana, a.n_filas),
    ROW(20, 'D20 OBS filas dentro de la ventana declarada del driver', CAST(0 AS BIGINT), a.o_en_ventana, a.n_filas)
]) AS t (orden, chk, n_viol, n_magnitud, n_base)
ORDER BY t.orden
