-- 2t1_l_mad_bpe.sql | TRAMO T1 | codmes 202206-202211 | CREATE (tmp descartable por tramo)
-- Sin literales de mes: hereda el acotado de tmp_mad_rcc, _rl, _sunat y _rccbwd del tramo.
-- Generado por gen_tramos.py: el texto es identico entre tramos salvo los literales de mes,
-- por eso la proyeccion del INSERT INTO coincide posicionalmente con la del CREATE TABLE.
-- 20f. Enriquecimiento BPE: RENIEC conyuge + especiales + flag_bpe_parcial -> disc_model_owner.ds_adm_bpe_bankbn_tmp_mad_bpe
--  1. Etapa 6 de 7. Ex CTE uni_conyuge, especiales, especiales_win, cruce_titular, base_cny, especial_cny,
--     base_flag_cny, flag_bpe. Junta ademas 20c (RRLL), 20d (SUNAT) y 20e (RCC pasado).
--  2. cruce_titular / base_flag_cny corren a grano (codmes, tip_doc, key_value): el RANK del original solo
--     depende de las llaves y de b.fecha_dt, no de las columnas anchas que arrastraba flag_bpe.
--  3. Q4 se conserva (base_cny solo evalua tip_doc <> '2'): A13 manda ESPECIALES a CASO1.
--  4. Q2 se conserva: '23. Ubigeo Restringido' no excluye en flag_malo_*, es CASO1 igual.
--  5. Grano de salida: (codmes, tip_doc, key_value).
CREATE TABLE disc_model_owner.ds_adm_bpe_bankbn_tmp_mad_bpe AS
WITH uni_mad AS (
    SELECT DISTINCT codmes, tip_doc, key_value
    FROM disc_model_owner.ds_adm_bpe_bankbn_tmp_mad_rcc
),
uni_conyuge AS (
    SELECT
        a.codmes,
        a.key_value,
        a.tip_doc,
        b.fec_nacimiento AS fec_nacimiento
    FROM (SELECT codmes, tip_doc, key_value FROM uni_mad WHERE tip_doc <> '2') a
    LEFT JOIN e_perm_aws.t_mst_reniec_rsk b
        ON a.key_value = b.key_value AND a.tip_doc = b.tip_doc
),
especiales AS (
    SELECT
        a.cliente_id,
        a.fecha_dt,
        CASE WHEN a.fecha_dt = '' THEN null ELSE substring(a.fecha_dt, 1, 10) END AS fechaingreso,
        CASE WHEN a.fecha_habilita_dt = '' THEN null ELSE substring(a.fecha_habilita_dt, 1, 10) END AS fechahabilita,
        b.cod_tipo_doc_val AS tip_doc,
        b.num_doc_val      AS key_value,
        CASE a.cod_tipo_val
            WHEN '1' THEN 'Negativo'
            WHEN '2' THEN 'Sobreendeudamiento'
            WHEN '3' THEN 'Vigilancia Especial'
            ELSE 'Error'
        END AS tipoingreso
    FROM (SELECT cliente_id, fecha_dt, fecha_habilita_dt, cod_tipo_val FROM e_perm_aws.t_rel_vpc_myp_clientenegativo GROUP BY 1,2,3,4) a
    JOIN (SELECT cliente_id, cod_tipo_doc_val, num_doc_val FROM e_perm_aws.t_mst_vpc_myp_cliente_actual GROUP BY 1,2,3) b
        ON a.cliente_id = b.cliente_id
),
especiales_win AS (
    SELECT *,
        DATE_FORMAT(DATE_TRUNC('MONTH', COALESCE(CAST(fechahabilita AS DATE), CURRENT_DATE)), '%Y%m') AS considerar_hasta,
        DATE_FORMAT(DATE_TRUNC('MONTH', CAST(fechaingreso AS DATE)), '%Y%m') AS codmesfechaingreso
    FROM especiales
    WHERE tipoingreso IN ('Vigilancia Especial', 'Sobreendeudamiento', 'Negativo')
),
cruce_titular AS (
    SELECT
        a.codmes,
        a.tip_doc,
        a.key_value,
        CASE WHEN b.tip_doc IS NOT NULL AND b.key_value IS NOT NULL THEN 'Cruce' ELSE 'No Cruce' END AS flagcruce,
        RANK() OVER (PARTITION BY a.codmes, a.tip_doc, a.key_value ORDER BY a.codmes, a.tip_doc, a.key_value, b.fecha_dt DESC) AS num
    FROM uni_mad a
    LEFT JOIN especiales_win b
        ON a.tip_doc = b.tip_doc
       AND a.key_value = b.key_value
       AND (a.codmes < b.considerar_hasta AND a.codmes >= b.codmesfechaingreso)
),
base_cny AS (
    SELECT
        a.codmes,
        a.key_value,
        a.tip_doc,
        b.tipdoc_conyugue,
        b.coddoc_conyugue,
        b.fec_inscripcion,
        RANK() OVER (PARTITION BY a.codmes, b.tipdoc_conyugue, b.coddoc_conyugue
                     ORDER BY a.codmes, b.tipdoc_conyugue, b.coddoc_conyugue, b.fec_inscripcion DESC) AS num
    FROM (SELECT * FROM cruce_titular WHERE tip_doc <> '2' AND num = 1) a
    INNER JOIN e_perm_aws.t_mst_reniec_rsk b
        ON a.key_value = b.key_value
       AND CAST(CAST(a.tip_doc AS INT) AS VARCHAR) = b.tip_doc
    WHERE TRIM(b.tipdoc_conyugue) <> ''
      AND TRIM(b.coddoc_conyugue) <> ''
),
especial_cny AS (
    SELECT
        a.codmes,
        a.tipdoc_conyugue,
        a.coddoc_conyugue,
        a.key_value,
        a.tip_doc,
        CASE WHEN b.tip_doc IS NOT NULL AND b.key_value IS NOT NULL THEN 'Cruce' ELSE 'No Cruce' END AS flagcruce_cny,
        RANK() OVER (PARTITION BY a.codmes, a.tip_doc, a.key_value ORDER BY a.codmes, a.tip_doc, a.key_value, b.fecha_dt DESC) AS num
    FROM (SELECT * FROM base_cny WHERE num = 1) a
    LEFT JOIN especiales_win b
        ON a.tipdoc_conyugue = b.tip_doc
       AND a.coddoc_conyugue = b.key_value
       AND (a.codmes < b.considerar_hasta AND a.codmes >= b.codmesfechaingreso)
),
base_flag_cny AS (
    SELECT
        a.codmes,
        a.tip_doc,
        a.key_value,
        a.flagcruce,
        b.flagcruce_cny
    FROM (SELECT * FROM cruce_titular WHERE num = 1) a
    LEFT JOIN (SELECT * FROM especial_cny WHERE num = 1) b
        ON a.codmes = b.codmes AND a.tip_doc = b.tip_doc AND a.key_value = b.key_value
)
SELECT
    x.codmes,
    x.tip_doc,
    x.key_value,
    rl.sld_castigado_12um_rl,
    rl.sld_castigado_12um_rl_v2,
    cy.fec_nacimiento,
    rl.fec_nacimiento_rl_min,
    rl.fec_nacimiento_rl_max,
    bw.saldo_novig_neg_12um,
    bw.saldo_novig_neg_12um_v2,
    bw.saldo_novig_neg_1um,
    bw.saldo_novig_neg_1um_m2,
    bw.saldo_nonormal_1um,
    bw.saldo_nonormal_1um_m2,
    su.tpoemp,
    su.estado,
    su.fecalta2,
    su.ciiu,
    su.ubigeo,
    su.cl_tpoemp,
    su.cl_estado,
    su.tipo_personeria,
    su.giro_restringido,
    su.ubigeo_restringido,
    su.flag_bpe_v1,
    su.flag_bpe_v2,
    CASE WHEN bw.saldo_novig_neg_1um > 0 THEN '01. Titular con Saldo Comercial No Vigente RCC (Ultimo mes)'
         WHEN bw.saldo_novig_neg_12um > 0 THEN '02. Titular con Saldo Comercial No Vigente RCC (Ultimos 12 meses)'
         WHEN bw.saldo_nonormal_1um > 0 THEN '03. Titular con Calificacion SBS diferente a 100% Normal'
         WHEN rl.sld_castigado_12um_rl > 0 THEN '09. RRLL con Saldo RCC en Castigo (Ultimos 12 meses)'
         WHEN (COALESCE(CAST(SUBSTRING(x.codmes,1,4) AS INT) - cast(EXTRACT(YEAR FROM cy.fec_nacimiento) AS int), 30) <= 25)
           OR (COALESCE(CAST(SUBSTRING(x.codmes,1,4) AS INT) - cast(EXTRACT(YEAR FROM cy.fec_nacimiento) AS int), 30) >= 75) THEN '17. Titular >= 75 o < 25 anos'
         WHEN (COALESCE(CAST(SUBSTRING(x.codmes,1,4) AS INT) - cast(EXTRACT(YEAR FROM rl.fec_nacimiento_rl_max) AS int), 30) <= 25)
           OR (COALESCE(CAST(SUBSTRING(x.codmes,1,4) AS INT) - cast(EXTRACT(YEAR FROM rl.fec_nacimiento_rl_min) AS int), 30) >= 75) THEN '18. RRLL >= 75 o < 25 anos'
         WHEN su.tipo_personeria = 'PPNN_SN' THEN '19. PNSN'
         WHEN su.estado NOT IN ('00','03') THEN '20. Estado Diferente A'
         WHEN su.giro_restringido = 1 THEN '22. Giro Restringido'
         WHEN su.ubigeo_restringido = 1 THEN '23. Ubigeo Restringido'
         ELSE '99. Sin Caida' END AS flag_bpe_parcial,
    x.flagcruce,
    x.flagcruce_cny
FROM base_flag_cny x
LEFT JOIN disc_model_owner.ds_adm_bpe_bankbn_tmp_mad_rl rl
    ON x.codmes = rl.codmes AND x.tip_doc = rl.tip_doc AND x.key_value = rl.key_value
LEFT JOIN uni_conyuge cy
    ON x.codmes = cy.codmes AND x.tip_doc = cy.tip_doc AND x.key_value = cy.key_value
LEFT JOIN disc_model_owner.ds_adm_bpe_bankbn_tmp_mad_rccbwd bw
    ON x.codmes = bw.codmes AND x.tip_doc = bw.tip_doc AND x.key_value = bw.key_value
LEFT JOIN disc_model_owner.ds_adm_bpe_bankbn_tmp_mad_sunat su
    ON x.codmes = su.codmes AND x.tip_doc = su.tip_doc AND x.key_value = su.key_value
