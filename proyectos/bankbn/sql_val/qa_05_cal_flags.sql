-- qa_05_cal_flags.sql | 24 invariantes de ds_adm_bpe_bankbn_cal: dominio y recomputo de flg_clean, conjuncion de flg_calib, entidad por codigo, dos ejes | REGLA UNICA: n_viol tiene que ser 0 en TODAS las filas
WITH b AS (
    SELECT
        codmes, tip_doc, key_value, cod_instit_financiera, entidad, segmento_reactiva,
        flg_clean, flg_calib, pd_raw, target_12m,
        falla_pd_raw, falla_entidad, falla_entidad_sin_mapa, falla_target_12m, falla_madurez, falla_dup,
        filtro_excl_entidades, filtro_pnsn, filtro_top4, filtro_reactiva_puro, filtro_impulsa_u12m, filtro_impulsa_m0,
        filtro_perfil_empresa + filtro_deuda_comercial + filtro_ent_honrada + filtro_alta + filtro_monto_endeud + filtro_saldo_vig_m0 AS s_neutral,
        filtro_perfil_empresa + filtro_deuda_comercial + filtro_ent_honrada + filtro_excl_entidades
      + filtro_alta + filtro_monto_endeud + filtro_saldo_vig_m0 + filtro_pnsn + filtro_top4
      + filtro_reactiva_puro + filtro_impulsa_u12m + filtro_impulsa_m0 AS s_est,
        filtro_castigado_org + filtro_judicial_org + filtro_reest_org + filtro_refin_org
      + filtro_clasif_no_normal + filtro_diasatraso_org + filtro_sbs_no_normal_1um + filtro_novig_1um
      + filtro_edad_titular + filtro_edad_rrll + filtro_novig_12um + filtro_rrll_cast_12um AS s_suc,
        CASE WHEN target_01m IS NULL OR target_02m IS NULL OR target_03m IS NULL OR target_04m IS NULL
                  OR target_05m IS NULL OR target_06m IS NULL OR target_07m IS NULL OR target_08m IS NULL
                  OR target_09m IS NULL OR target_10m IS NULL OR target_11m IS NULL OR target_12m IS NULL
             THEN 1 ELSE 0 END AS fam_incompleta,
        CASE cod_instit_financiera WHEN '00001' THEN 'BCP' WHEN '00002' THEN 'IBK' WHEN '00004' THEN 'SCOTIA' WHEN '00006' THEN 'BBVA' ELSE 'OTRO' END AS ent_esp
    FROM disc_model_owner.ds_adm_bpe_bankbn_cal
),
a AS (
    SELECT
        CAST(count(1) AS BIGINT) AS n_filas,
        CAST(count(DISTINCT CAST(codmes AS VARCHAR) || '#' || CAST(tip_doc AS VARCHAR) || '#' || CAST(key_value AS VARCHAR)) AS BIGINT) AS n_granos,
        CAST(count(DISTINCT CAST(codmes AS VARCHAR)) AS BIGINT) AS n_meses,
        min(CAST(codmes AS VARCHAR)) AS mes_min,
        max(CAST(codmes AS VARCHAR)) AS mes_max,
        CAST(sum(CASE WHEN flg_clean = 99 THEN 1 ELSE 0 END) AS BIGINT) AS n_99,
        CAST(sum(CASE WHEN flg_clean = 1 THEN 1 ELSE 0 END) AS BIGINT) AS n_1,
        CAST(sum(CASE WHEN flg_clean = 0 THEN 1 ELSE 0 END) AS BIGINT) AS n_0,
        CAST(sum(CASE WHEN flg_calib = 1 THEN 1 ELSE 0 END) AS BIGINT) AS n_calib,
        CAST(sum(CASE WHEN flg_clean IS NULL OR flg_clean NOT IN (99, 1, 0) THEN 1 ELSE 0 END) AS BIGINT) AS v_dominio,
        CAST(sum(CASE WHEN flg_clean = 98 THEN 1 ELSE 0 END) AS BIGINT) AS v_98,
        CAST(sum(CASE WHEN COALESCE(flg_clean, -1) <> (CASE WHEN s_est IS NULL OR s_suc IS NULL THEN -2 WHEN s_est > 0 THEN 99 WHEN s_suc = 0 THEN 1 ELSE 0 END) THEN 1 ELSE 0 END) AS BIGINT) AS v_recalc,
        CAST(sum(CASE WHEN COALESCE(flg_calib, -1) <> (CASE WHEN flg_clean <> 99 AND pd_raw IS NOT NULL AND falla_madurez = 0 THEN 1 ELSE 0 END) THEN 1 ELSE 0 END) AS BIGINT) AS v_calib,
        CAST(sum(CASE WHEN flg_calib = 1 AND flg_clean = 99 THEN 1 ELSE 0 END) AS BIGINT) AS v_calib99,
        CAST(sum(CASE WHEN flg_calib = 1 AND pd_raw IS NULL THEN 1 ELSE 0 END) AS BIGINT) AS v_calibsinpd,
        CAST(sum(CASE WHEN flg_calib = 1 AND target_12m IS NULL THEN 1 ELSE 0 END) AS BIGINT) AS v_calibtnull,
        CAST(sum(CASE WHEN flg_calib = 1 AND fam_incompleta = 1 THEN 1 ELSE 0 END) AS BIGINT) AS v_calibfam,
        CAST(sum(CASE WHEN falla_madurez <> falla_target_12m THEN 1 ELSE 0 END) AS BIGINT) AS v_madvs12,
        CAST(sum(CASE WHEN pd_raw IS NULL AND falla_pd_raw = 0 THEN 1 ELSE 0 END) AS BIGINT) AS v_pdcast,
        CAST(sum(CASE WHEN pd_raw IS NOT NULL AND (pd_raw <= 0 OR pd_raw >= 1) THEN 1 ELSE 0 END) AS BIGINT) AS v_pdrango,
        CAST(sum(falla_dup) AS BIGINT) AS v_dup,
        CAST(sum(CASE WHEN entidad IS DISTINCT FROM ent_esp THEN 1 ELSE 0 END) AS BIGINT) AS v_entidad,
        CAST(sum(CASE WHEN filtro_top4 <> (CASE WHEN entidad IN ('BCP','BBVA','SCOTIA','IBK') THEN 0 ELSE 1 END) THEN 1 ELSE 0 END) AS BIGINT) AS v_top4,
        CAST(sum(filtro_excl_entidades) AS BIGINT) AS v_excl,
        CAST(sum(falla_entidad) AS BIGINT) AS v_fallaent,
        CAST(sum(CASE WHEN s_neutral <> 0 THEN 1 ELSE 0 END) AS BIGINT) AS v_neutral,
        CAST(sum(CASE WHEN segmento_reactiva IS NULL OR segmento_reactiva NOT IN ('SOLO NEGOCIO','MIXTO','REACTIVA','SIN DEUDA') THEN 1 ELSE 0 END) AS BIGINT) AS v_segdom,
        CAST(sum(CASE WHEN filtro_reactiva_puro <> (CASE WHEN segmento_reactiva = 'REACTIVA' THEN 1 ELSE 0 END) THEN 1 ELSE 0 END) AS BIGINT) AS v_reactflag,
        CAST(sum(CASE WHEN filtro_pnsn = 1 AND flg_clean <> 99 THEN 1 ELSE 0 END) AS BIGINT) AS v_pnsn,
        CAST(sum(CASE WHEN flg_calib = 1 AND flg_clean = 1 THEN 1 ELSE 0 END) AS BIGINT) AS o_calib_c1,
        CAST(sum(CASE WHEN flg_calib = 1 AND flg_clean = 0 THEN 1 ELSE 0 END) AS BIGINT) AS o_calib_c0,
        CAST(sum(CASE WHEN flg_clean = 1 AND pd_raw IS NULL THEN 1 ELSE 0 END) AS BIGINT) AS o_c1_sinpd,
        CAST(sum(CASE WHEN entidad = 'IBK' THEN 1 ELSE 0 END) AS BIGINT) AS o_ibk,
        CAST(sum(CASE WHEN entidad = 'BCP' THEN 1 ELSE 0 END) AS BIGINT) AS o_bcp,
        CAST(sum(CASE WHEN entidad = 'OTRO' THEN 1 ELSE 0 END) AS BIGINT) AS o_otro,
        CAST(count(DISTINCT CASE WHEN flg_calib = 1 THEN CAST(codmes AS VARCHAR) END) AS BIGINT) AS o_meses_calib,
        min(CASE WHEN flg_calib = 1 THEN CAST(codmes AS VARCHAR) END) AS o_calib_min,
        max(CASE WHEN flg_calib = 1 THEN CAST(codmes AS VARCHAR) END) AS o_calib_max
    FROM b
)
SELECT
    t.orden,
    t.chk,
    t.n_viol,
    t.n_magnitud,
    round(100e0 * t.n_magnitud / nullif(a.n_filas, 0), 5) AS pct_magnitud,
    CASE WHEN t.n_viol = 0 THEN 'OK' ELSE 'REVISAR' END AS veredicto,
    a.n_filas,
    a.n_meses,
    a.mes_min,
    a.mes_max,
    a.n_99,
    a.n_1,
    a.n_0,
    a.n_calib,
    a.o_meses_calib,
    a.o_calib_min,
    a.o_calib_max
FROM a
CROSS JOIN UNNEST(ARRAY[
    ROW(1, 'C01 flg_clean fuera del dominio 99 1 0', a.v_dominio, a.v_dominio),
    ROW(2, 'C02 bucket 98 sobrevivio A23a', a.v_98, a.v_98),
    ROW(3, 'C03 flg_clean recomputado desde los 24 filtros no coincide', a.v_recalc, a.v_recalc),
    ROW(4, 'C04 flg_calib no es la conjuncion de A23b', a.v_calib, a.v_calib),
    ROW(5, 'C05 calibrable con flg_clean 99', a.v_calib99, a.v_calib99),
    ROW(6, 'C06 calibrable sin pd_raw', a.v_calibsinpd, a.v_calibsinpd),
    ROW(7, 'C07 calibrable con target_12m NULL', a.v_calibtnull, a.v_calibtnull),
    ROW(8, 'C08 calibrable con familia target_01m..12m incompleta', a.v_calibfam, a.v_calibfam),
    ROW(9, 'C09 falla_madurez distinto de falla_target_12m', a.v_madvs12, a.v_madvs12),
    ROW(10, 'C10 pd_raw NULL con falla_pd_raw 0 el TRY_CAST se comio valores', a.v_pdcast, a.v_pdcast),
    ROW(11, 'C11 pd_raw fuera del intervalo 0 1', a.v_pdrango, a.v_pdrango),
    ROW(12, 'C12 falla_dup grano cliente-mes duplicado', a.v_dup, a.n_filas - a.n_granos),
    ROW(13, 'C13 entidad no corresponde al codigo A21', a.v_entidad, a.v_entidad),
    ROW(14, 'C14 filtro_top4 incoherente con entidad', a.v_top4, a.v_top4),
    ROW(15, 'C15 filtro_excl_entidades prendido A24 ya lo aplico la PO', a.v_excl, a.v_excl),
    ROW(16, 'C16 falla_entidad codigo de entidad NULL', a.v_fallaent, a.v_fallaent),
    ROW(17, 'C17 alguno de los 6 filtros neutralizados no vale 0', a.v_neutral, a.v_neutral),
    ROW(18, 'C18 segmento_reactiva fuera de dominio', a.v_segdom, a.v_segdom),
    ROW(19, 'C19 filtro_reactiva_puro no equivale a segmento REACTIVA', a.v_reactflag, a.v_reactflag),
    ROW(20, 'C20 filtro_pnsn prendido sin caer al bucket 99', a.v_pnsn, a.v_pnsn),
    ROW(21, 'C21 particion 99+1+0 no cubre la tabla', a.n_filas - a.n_99 - a.n_1 - a.n_0, a.n_filas),
    ROW(22, 'C22 eje dirty vacio n_magnitud debe ser mayor que 0', CAST(CASE WHEN a.o_calib_c0 = 0 THEN 1 ELSE 0 END AS BIGINT), a.o_calib_c0),
    ROW(23, 'C23 eje clean vacio n_magnitud debe ser mayor que 0', CAST(CASE WHEN a.o_calib_c1 = 0 THEN 1 ELSE 0 END AS BIGINT), a.o_calib_c1),
    ROW(24, 'C24 limpio sin score inexistente sustento de A23a n_magnitud debe ser mayor que 0', CAST(CASE WHEN a.o_c1_sinpd = 0 THEN 1 ELSE 0 END AS BIGINT), a.o_c1_sinpd),
    ROW(25, 'C25 OBS entidad IBK BCP OTRO en n_magnitud ver notas', CAST(0 AS BIGINT), a.o_ibk),
    ROW(26, 'C26 OBS huecos de mes en la cobertura', CAST(date_diff('month', date_parse(a.mes_min, '%Y%m'), date_parse(a.mes_max, '%Y%m')) + 1 - a.n_meses AS BIGINT), a.n_meses)
]) AS t (orden, chk, n_viol, n_magnitud)
ORDER BY t.orden
