-- qa_06_cascada_filtros.sql | los 30 filtros de ds_adm_bpe_bankbn_cal en orden de cascada: marca bruta, mortalidad marginal y veredicto MUERTO TAPADO TRAGA_TODO | 30 filas
WITH k AS (
    SELECT
        filtro_perfil_empresa AS f01, filtro_deuda_comercial AS f02, filtro_ent_honrada AS f03,
        filtro_excl_entidades AS f04, filtro_alta AS f05, filtro_monto_endeud AS f06,
        filtro_saldo_vig_m0 AS f07, filtro_pnsn AS f08, filtro_top4 AS f09,
        filtro_reactiva_puro AS f10, filtro_impulsa_u12m AS f11, filtro_impulsa_m0 AS f12,
        filtro_castigado_org AS f13, filtro_judicial_org AS f14, filtro_reest_org AS f15,
        filtro_refin_org AS f16, filtro_clasif_no_normal AS f17, filtro_diasatraso_org AS f18,
        filtro_sbs_no_normal_1um AS f19, filtro_novig_1um AS f20, filtro_edad_titular AS f21,
        filtro_edad_rrll AS f22, filtro_novig_12um AS f23, filtro_rrll_cast_12um AS f24,
        filtro_sunat_estado AS f25, filtro_sunat_giro AS f26, filtro_sunat_ubigeo AS f27,
        filtro_especiales AS f28, filtro_indeterminado AS f29, filtro_madurez_blanda AS f30,
        CASE WHEN filtro_perfil_empresa = 1 THEN 1
             WHEN filtro_deuda_comercial = 1 THEN 2
             WHEN filtro_ent_honrada = 1 THEN 3
             WHEN filtro_excl_entidades = 1 THEN 4
             WHEN filtro_alta = 1 THEN 5
             WHEN filtro_monto_endeud = 1 THEN 6
             WHEN filtro_saldo_vig_m0 = 1 THEN 7
             WHEN filtro_pnsn = 1 THEN 8
             WHEN filtro_top4 = 1 THEN 9
             WHEN filtro_reactiva_puro = 1 THEN 10
             WHEN filtro_impulsa_u12m = 1 THEN 11
             WHEN filtro_impulsa_m0 = 1 THEN 12
             WHEN filtro_castigado_org = 1 THEN 13
             WHEN filtro_judicial_org = 1 THEN 14
             WHEN filtro_reest_org = 1 THEN 15
             WHEN filtro_refin_org = 1 THEN 16
             WHEN filtro_clasif_no_normal = 1 THEN 17
             WHEN filtro_diasatraso_org = 1 THEN 18
             WHEN filtro_sbs_no_normal_1um = 1 THEN 19
             WHEN filtro_novig_1um = 1 THEN 20
             WHEN filtro_edad_titular = 1 THEN 21
             WHEN filtro_edad_rrll = 1 THEN 22
             WHEN filtro_novig_12um = 1 THEN 23
             WHEN filtro_rrll_cast_12um = 1 THEN 24
             WHEN filtro_sunat_estado = 1 THEN 25
             WHEN filtro_sunat_giro = 1 THEN 26
             WHEN filtro_sunat_ubigeo = 1 THEN 27
             WHEN filtro_especiales = 1 THEN 28
             WHEN filtro_indeterminado = 1 THEN 29
             WHEN filtro_madurez_blanda = 1 THEN 30
             ELSE 31 END AS ok
    FROM disc_model_owner.ds_adm_bpe_bankbn_cal
),
a AS (
    SELECT
        CAST(count(1) AS BIGINT) AS n_tot,
        CAST(sum(f01) AS BIGINT) AS b01, CAST(sum(f02) AS BIGINT) AS b02, CAST(sum(f03) AS BIGINT) AS b03,
        CAST(sum(f04) AS BIGINT) AS b04, CAST(sum(f05) AS BIGINT) AS b05, CAST(sum(f06) AS BIGINT) AS b06,
        CAST(sum(f07) AS BIGINT) AS b07, CAST(sum(f08) AS BIGINT) AS b08, CAST(sum(f09) AS BIGINT) AS b09,
        CAST(sum(f10) AS BIGINT) AS b10, CAST(sum(f11) AS BIGINT) AS b11, CAST(sum(f12) AS BIGINT) AS b12,
        CAST(sum(f13) AS BIGINT) AS b13, CAST(sum(f14) AS BIGINT) AS b14, CAST(sum(f15) AS BIGINT) AS b15,
        CAST(sum(f16) AS BIGINT) AS b16, CAST(sum(f17) AS BIGINT) AS b17, CAST(sum(f18) AS BIGINT) AS b18,
        CAST(sum(f19) AS BIGINT) AS b19, CAST(sum(f20) AS BIGINT) AS b20, CAST(sum(f21) AS BIGINT) AS b21,
        CAST(sum(f22) AS BIGINT) AS b22, CAST(sum(f23) AS BIGINT) AS b23, CAST(sum(f24) AS BIGINT) AS b24,
        CAST(sum(f25) AS BIGINT) AS b25, CAST(sum(f26) AS BIGINT) AS b26, CAST(sum(f27) AS BIGINT) AS b27,
        CAST(sum(f28) AS BIGINT) AS b28, CAST(sum(f29) AS BIGINT) AS b29, CAST(sum(f30) AS BIGINT) AS b30,
        CAST(sum(CASE WHEN ok >= 1 THEN 1 ELSE 0 END) AS BIGINT) AS v01,
        CAST(sum(CASE WHEN ok >= 2 THEN 1 ELSE 0 END) AS BIGINT) AS v02,
        CAST(sum(CASE WHEN ok >= 3 THEN 1 ELSE 0 END) AS BIGINT) AS v03,
        CAST(sum(CASE WHEN ok >= 4 THEN 1 ELSE 0 END) AS BIGINT) AS v04,
        CAST(sum(CASE WHEN ok >= 5 THEN 1 ELSE 0 END) AS BIGINT) AS v05,
        CAST(sum(CASE WHEN ok >= 6 THEN 1 ELSE 0 END) AS BIGINT) AS v06,
        CAST(sum(CASE WHEN ok >= 7 THEN 1 ELSE 0 END) AS BIGINT) AS v07,
        CAST(sum(CASE WHEN ok >= 8 THEN 1 ELSE 0 END) AS BIGINT) AS v08,
        CAST(sum(CASE WHEN ok >= 9 THEN 1 ELSE 0 END) AS BIGINT) AS v09,
        CAST(sum(CASE WHEN ok >= 10 THEN 1 ELSE 0 END) AS BIGINT) AS v10,
        CAST(sum(CASE WHEN ok >= 11 THEN 1 ELSE 0 END) AS BIGINT) AS v11,
        CAST(sum(CASE WHEN ok >= 12 THEN 1 ELSE 0 END) AS BIGINT) AS v12,
        CAST(sum(CASE WHEN ok >= 13 THEN 1 ELSE 0 END) AS BIGINT) AS v13,
        CAST(sum(CASE WHEN ok >= 14 THEN 1 ELSE 0 END) AS BIGINT) AS v14,
        CAST(sum(CASE WHEN ok >= 15 THEN 1 ELSE 0 END) AS BIGINT) AS v15,
        CAST(sum(CASE WHEN ok >= 16 THEN 1 ELSE 0 END) AS BIGINT) AS v16,
        CAST(sum(CASE WHEN ok >= 17 THEN 1 ELSE 0 END) AS BIGINT) AS v17,
        CAST(sum(CASE WHEN ok >= 18 THEN 1 ELSE 0 END) AS BIGINT) AS v18,
        CAST(sum(CASE WHEN ok >= 19 THEN 1 ELSE 0 END) AS BIGINT) AS v19,
        CAST(sum(CASE WHEN ok >= 20 THEN 1 ELSE 0 END) AS BIGINT) AS v20,
        CAST(sum(CASE WHEN ok >= 21 THEN 1 ELSE 0 END) AS BIGINT) AS v21,
        CAST(sum(CASE WHEN ok >= 22 THEN 1 ELSE 0 END) AS BIGINT) AS v22,
        CAST(sum(CASE WHEN ok >= 23 THEN 1 ELSE 0 END) AS BIGINT) AS v23,
        CAST(sum(CASE WHEN ok >= 24 THEN 1 ELSE 0 END) AS BIGINT) AS v24,
        CAST(sum(CASE WHEN ok >= 25 THEN 1 ELSE 0 END) AS BIGINT) AS v25,
        CAST(sum(CASE WHEN ok >= 26 THEN 1 ELSE 0 END) AS BIGINT) AS v26,
        CAST(sum(CASE WHEN ok >= 27 THEN 1 ELSE 0 END) AS BIGINT) AS v27,
        CAST(sum(CASE WHEN ok >= 28 THEN 1 ELSE 0 END) AS BIGINT) AS v28,
        CAST(sum(CASE WHEN ok >= 29 THEN 1 ELSE 0 END) AS BIGINT) AS v29,
        CAST(sum(CASE WHEN ok >= 30 THEN 1 ELSE 0 END) AS BIGINT) AS v30,
        CAST(sum(CASE WHEN ok >= 31 THEN 1 ELSE 0 END) AS BIGINT) AS v31
    FROM k
)
SELECT
    t.orden,
    t.grupo,
    t.filtro,
    a.n_tot AS n_total,
    t.n_marca,
    t.n_entra,
    t.n_entra - t.n_queda AS n_mata,
    t.n_queda,
    round(CAST(t.n_marca AS DOUBLE) / nullif(CAST(a.n_tot AS DOUBLE), 0), 6) AS tasa_bruta,
    round(CAST(t.n_entra - t.n_queda AS DOUBLE) / nullif(CAST(t.n_entra AS DOUBLE), 0), 6) AS tasa_marginal,
    t.excepcion,
    CASE WHEN a.n_tot = 0 THEN 'TABLA_VACIA'
         WHEN t.grupo = 'X_NEUTRALIZADO' AND t.n_marca = 0 THEN 'OK_NEUTRALIZADO'
         WHEN t.grupo = 'X_NEUTRALIZADO' THEN 'FALLA_NEUTRAL_ROTO'
         WHEN t.n_marca = 0 THEN 'ALERTA_MUERTO'
         WHEN t.n_entra - t.n_queda = 0 THEN 'ALERTA_TAPADO'
         WHEN t.n_entra > 0 AND t.n_entra - t.n_queda = t.n_entra THEN 'ALERTA_TRAGA_TODO'
         ELSE 'OK' END AS veredicto
FROM a
CROSS JOIN UNNEST(ARRAY[
    ROW(1, 'X_NEUTRALIZADO', 'filtro_perfil_empresa', a.b01, a.v01, a.v02, 'aplicado en 1tN_f_altas tipo_credito 08-10'),
    ROW(2, 'X_NEUTRALIZADO', 'filtro_deuda_comercial', a.b02, a.v02, a.v03, 'aplicado en 1tN_b_tag'),
    ROW(3, 'X_NEUTRALIZADO', 'filtro_ent_honrada', a.b03, a.v03, a.v04, 'aplicado en 1tN_b_tag ent_honrada=0'),
    ROW(4, 'A_GATE_99', 'filtro_excl_entidades', a.b04, a.v04, a.v05, 'MUERTO ESPERADO A24 ya aplicado en 1tN_h_po'),
    ROW(5, 'X_NEUTRALIZADO', 'filtro_alta', a.b05, a.v05, a.v06, 'aplicado en 1tN_h_po alta2=1'),
    ROW(6, 'X_NEUTRALIZADO', 'filtro_monto_endeud', a.b06, a.v06, a.v07, 'aplicado en 2tN_b_mad_rcc 30k 10k'),
    ROW(7, 'X_NEUTRALIZADO', 'filtro_saldo_vig_m0', a.b07, a.v07, a.v08, 'aplicado en 2tN_b_mad_rcc saldo_vig_m0>0'),
    ROW(8, 'A_GATE_99', 'filtro_pnsn', a.b08, a.v08, a.v09, '-'),
    ROW(9, 'A_GATE_99', 'filtro_top4', a.b09, a.v09, a.v10, '-'),
    ROW(10, 'A_GATE_99', 'filtro_reactiva_puro', a.b10, a.v10, a.v11, '-'),
    ROW(11, 'A_GATE_99', 'filtro_impulsa_u12m', a.b11, a.v11, a.v12, '-'),
    ROW(12, 'A_GATE_99', 'filtro_impulsa_m0', a.b12, a.v12, a.v13, '-'),
    ROW(13, 'B_GATE_DIRTY', 'filtro_castigado_org', a.b13, a.v13, a.v14, '-'),
    ROW(14, 'B_GATE_DIRTY', 'filtro_judicial_org', a.b14, a.v14, a.v15, '-'),
    ROW(15, 'B_GATE_DIRTY', 'filtro_reest_org', a.b15, a.v15, a.v16, '-'),
    ROW(16, 'B_GATE_DIRTY', 'filtro_refin_org', a.b16, a.v16, a.v17, '-'),
    ROW(17, 'B_GATE_DIRTY', 'filtro_clasif_no_normal', a.b17, a.v17, a.v18, '-'),
    ROW(18, 'B_GATE_DIRTY', 'filtro_diasatraso_org', a.b18, a.v18, a.v19, '-'),
    ROW(19, 'B_GATE_DIRTY', 'filtro_sbs_no_normal_1um', a.b19, a.v19, a.v20, '-'),
    ROW(20, 'B_GATE_DIRTY', 'filtro_novig_1um', a.b20, a.v20, a.v21, '-'),
    ROW(21, 'B_GATE_DIRTY', 'filtro_edad_titular', a.b21, a.v21, a.v22, 'si sale MUERTO el join RENIEC murio y el COALESCE 30 lo tapa'),
    ROW(22, 'B_GATE_DIRTY', 'filtro_edad_rrll', a.b22, a.v22, a.v23, 'si sale MUERTO el join RRLL murio'),
    ROW(23, 'B_GATE_DIRTY', 'filtro_novig_12um', a.b23, a.v23, a.v24, '-'),
    ROW(24, 'B_GATE_DIRTY', 'filtro_rrll_cast_12um', a.b24, a.v24, a.v25, '-'),
    ROW(25, 'C_NO_GATEA', 'filtro_sunat_estado', a.b25, a.v25, a.v26, 'CASO1 no gatea'),
    ROW(26, 'C_NO_GATEA', 'filtro_sunat_giro', a.b26, a.v26, a.v27, 'CASO1 A25 subcuenta por cascada'),
    ROW(27, 'C_NO_GATEA', 'filtro_sunat_ubigeo', a.b27, a.v27, a.v28, 'CASO1 Q2 puede salir MUERTO'),
    ROW(28, 'C_NO_GATEA', 'filtro_especiales', a.b28, a.v28, a.v29, 'CASO1 Q4'),
    ROW(29, 'C_NO_GATEA', 'filtro_indeterminado', a.b29, a.v29, a.v30, 'CASO1 A3 no debe excluir'),
    ROW(30, 'C_NO_GATEA', 'filtro_madurez_blanda', a.b30, a.v30, a.v31, 'CASO1 A3 madurez calendario')
]) AS t (orden, grupo, filtro, n_marca, n_entra, n_queda, excepcion)
ORDER BY t.orden
