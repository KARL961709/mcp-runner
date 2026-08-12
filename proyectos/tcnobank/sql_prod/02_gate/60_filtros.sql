-- ============================================================================
-- 60. FILTROS - UNA COLUMNA POR FILTRO, NUNCA NULL
-- ============================================================================
CREATE TABLE disc_model_owner.ds_adm_vcnbank_tc_60_filtros
WITH (
    format              = 'PARQUET',
    parquet_compression = 'SNAPPY',
    partitioned_by      = ARRAY['codmes_mrm']
) AS
WITH po AS (
    SELECT codmes_mrm, tip_doc, id_value, entidad, sbs_value, cod_cuc, saldo_tc_ori,
           falla_sin_sbs, falla_sin_cuc, date_format(date_add('month', -2, date_parse(codmes_mrm, '%Y%m')), '%Y%m') AS m02, date_format(date_add('month', 12, date_parse(codmes_mrm, '%Y%m')), '%Y%m') AS p12
    FROM disc_model_owner.ds_adm_vcnbank_tc_11_po_key
),
gar AS (
    SELECT p_codmes, sbs_value,
           max(CASE WHEN cons_salgarhip > 0 THEN 1 ELSE 0 END)                         AS f_gar,
           max(CASE WHEN cons_salprestnorevconv > 0 OR cons_salprestrevconv > 0
                      OR cons_salpresconvob    > 0 THEN 1 ELSE 0 END)                  AS f_conv
    FROM e_perm_aws.t_consolidado_rsk
    GROUP BY p_codmes, sbs_value
),
fra AS (
    SELECT tip_doc, key_value, min(p_codmes) AS p_codmes_min
    FROM e_perm_aws.t_mst_fraude_rsk
    GROUP BY tip_doc, key_value
),
fac AS (
    SELECT codunicocli, CAST(periodo AS VARCHAR) AS codmes,
           max(CASE WHEN facilidad = 'SWAP' THEN 1 ELSE 0 END)                         AS f_swap,
           max(CASE WHEN facilidad = 'REPROGRAMACION'
                     AND tipo_facilidad IN ('LLUVIAS','UNILATERAL_LLUVIAS','SOCIAL')
                    THEN 1 ELSE 0 END)                                                 AS f_repro
    FROM e_perm_aws.t_cob_facilidades_ejecutadas
    WHERE estado_facilidad = 'EJECUTADO'
    GROUP BY codunicocli, CAST(periodo AS VARCHAR)
)
SELECT p.tip_doc,
       p.id_value,
       p.entidad,
       p.saldo_tc_ori,
       CAST(coalesce(CASE WHEN r.fec_nacimiento IS NOT NULL
                           AND NOT (date_diff('year', CAST(r.fec_nacimiento AS DATE),
                                              CAST(date_parse(p.codmes_mrm || '01', '%Y%m%d') AS DATE))
                                    BETWEEN 21 AND 75)
                          THEN 1 ELSE 0 END, 0) AS INTEGER)                            AS f_edad_rango,
       CAST(CASE WHEN r.key_value IS NULL OR r.fec_nacimiento IS NULL THEN 1 ELSE 0 END AS INTEGER) AS f_edad_nomatch,
       CAST(coalesce(h.banc_u12m,   0) AS INTEGER)                                     AS f_banc_u12m,
       CAST(coalesce(b.cast_ori_m2, 0) AS INTEGER)                                     AS f_cast_ori,
       CAST(coalesce(b.jud_ori_m2,  0) AS INTEGER)                                     AS f_jud_ori,
       CAST(coalesce(b.ref_ori_m2,  0) AS INTEGER)                                     AS f_ref_ori,
       CAST(coalesce(b.ree_ori_m2,  0) AS INTEGER)                                     AS f_ree_ori,
       CAST(coalesce(b.malo_ori_m2, 0) AS INTEGER)                                     AS f_malo_ori,
       CAST(coalesce(h.cast_u24m,   0) AS INTEGER)                                     AS f_cast_u24m,
       CAST(coalesce(h.jud_u24m,    0) AS INTEGER)                                     AS f_jud_u24m,
       CAST(coalesce(h.ref_u6m,     0) AS INTEGER)                                     AS f_ref_u6m,
       CAST(coalesce(h.mayor_cpp,   0) AS INTEGER)                                     AS f_mayor_cpp,
       CAST(coalesce(greatest(g.f_gar, g.f_conv), 0) AS INTEGER)                       AS f_gar_conv,
       CAST(coalesce(CASE WHEN fr.p_codmes_min <= p.m02 THEN 1 ELSE 0 END, 0) AS INTEGER) AS f_fraude,
       CAST(CASE WHEN p.entidad IN ('00001','00002','00004','00006','00142')
                 THEN 0 ELSE 1 END AS INTEGER)                                         AS f_entidades,
       CAST(coalesce(su.f_swap,  0) AS INTEGER)                                        AS f_swap_u12m,
       CAST(coalesce(sp.f_swap,  0) AS INTEGER)                                        AS f_swap_p12m,
       CAST(coalesce(sp.f_repro, 0) AS INTEGER)                                        AS f_repro_p12m,
       CAST(coalesce(b.cast_ori_m0, 0) AS INTEGER)                                     AS ctrl_cast_ori_m0,
       CAST(coalesce(b.jud_ori_m0,  0) AS INTEGER)                                     AS ctrl_jud_ori_m0,
       CAST(coalesce(b.ref_ori_m0,  0) AS INTEGER)                                     AS ctrl_ref_ori_m0,
       CAST(coalesce(b.ree_ori_m0,  0) AS INTEGER)                                     AS ctrl_ree_ori_m0,
       CAST(coalesce(b.malo_ori_m0, 0) AS INTEGER)                                     AS ctrl_malo_ori_m0,
       CAST(CASE WHEN p.codmes_mrm < '202106' THEN 1 ELSE 0 END AS INTEGER)            AS ctrl_sin_fraude,
       CAST(CASE WHEN p.codmes_mrm < '202201' THEN 1 ELSE 0 END AS INTEGER)            AS ctrl_sin_swap,
       CAST(coalesce(h.ctrl_no_consumo, 0) AS INTEGER)                                 AS ctrl_no_consumo,
       CAST(p.falla_sin_sbs AS INTEGER)                                                AS falla_sin_sbs,
       CAST(p.falla_sin_cuc AS INTEGER)                                                AS falla_sin_cuc,
       CAST(coalesce(h.falla_sin_historia, 1) AS INTEGER)                              AS falla_sin_historia,
       p.codmes_mrm
FROM po p
LEFT JOIN disc_model_owner.ds_adm_vcnbank_tc_20_rcc_base  b ON b.tip_doc = p.tip_doc AND b.id_value = p.id_value
                              AND b.entidad = p.entidad AND b.codmes_mrm = p.codmes_mrm
LEFT JOIN disc_model_owner.ds_adm_vcnbank_tc_21_rcc_flags h ON h.tip_doc = p.tip_doc AND h.id_value = p.id_value
                              AND h.entidad = p.entidad AND h.codmes_mrm = p.codmes_mrm
LEFT JOIN e_perm_aws.t_mst_reniec_rsk r ON r.tip_doc = p.tip_doc AND r.key_value = p.id_value
LEFT JOIN gar g  ON g.sbs_value = p.sbs_value AND g.p_codmes = p.m02
LEFT JOIN fra fr ON fr.tip_doc  = p.tip_doc   AND fr.key_value = p.id_value
LEFT JOIN fac su ON su.codunicocli = p.cod_cuc
                AND su.codmes BETWEEN date_format(date_add('month', -12, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') AND date_format(date_add('month', -1, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m')
LEFT JOIN fac sp ON sp.codunicocli = p.cod_cuc
                AND sp.codmes BETWEEN date_format(date_add('month', 1, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') AND p.p12
