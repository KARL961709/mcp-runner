-- 2t5_l_mad.sql | ensamblado final target y score | escribe 202306-202505 lee score 202305-202504
CREATE TABLE disc_model_owner.ds_adm_bpe_bankbn_mad_t5 AS
WITH score AS (
    SELECT *
    FROM e_perm_aws.scr_admbankbpe_rsk
    WHERE p_codmes BETWEEN '202305' AND '202504'
)
SELECT
  a.codmes,
  a.codmes AS p_codmes,
  a.tip_doc,
  a.key_value,
  a.cod_instit_financiera,
  a.nombre_instit_financiera,
  a.ent_alta,

  b.puntuacion,
  b.probabilidad,
  b.woe_beta_sldoppcomer,
  b.woe_prm_decresldo12m,
  b.woe_nro_decresldo12m,
  b.woe_beta_nroenti,
  b.woe_max_nrocredsldo06m,
  b.woe_prm_porcsldoimpa12m,
  b.woe_peor_clasicony09m,
  b.woe_prm_decresldopp12m,
  b.woe_prm_usotcfueraibk12m,
  b.woe_prm_decresldotc12m,
  b.woe_beta_sldopp12m,
  b.woe_max_dismsldonoprinc12m,
  b.woe_max_nroentinegocny06m,
  b.woe_nro_mesesatrasmay8dias09m,
  b.woe_max_dismsldoretail03m,
  b.woe_beta_sldotc12m,
  b.woe_rat_sldo09msobre12mrl,
  b.woe_max_diasatras09mrl,
  b.woe_nro_dismsaldonormal12mcny,
  b.woe_max_dismsldo12rl,
  b.woe_nro_mesesdismsldoretail12m,
  b.woe_rat_sldonormal3msobre12mrl,
  b.woe_porc_messldogiro06m,
  b.woe_prm_ratdispefect03m,
  b.woe_nro_mesesdicmsldoprinc12m,
  b.woe_prm_valorexpimp12m,
  b.woe_min_sldopasi06m,
  b.woe_cant_entireportsisnoreg,
  b.woe_prm_deudatelco12m,
  b.woe_cant_vehi,
  b.woe_anti_negmeses,
  b.woe_prm_nrotrxcashout06m,
  b.woe_nro_mesescastin06m,
  b.woe_edad,
  b.woe_dpt_grupo_v2,
  b.woe_ciiu_grupo_v2,
  b.rat_promsldnegdecreprin3y6m,
  b.rat_promsldnegdecre03y06m,
  b.woe_avg_porcsald_otrasent12m,

  a.dm_fm1,
  a.dm_fm2,
  a.dm_fm3,
  a.dm_fm4,
  a.dm_fm5,
  a.dm_fm6,
  a.dm_fm7,
  a.dm_fm8,
  a.dm_fm9,
  a.dm_fm10,
  a.dm_fm11,
  a.dm_fm12,

  a.sld_m1,
  a.sld_m2,
  a.sld_m3,
  a.sld_m4,
  a.sld_m5,
  a.sld_m6,
  a.sld_m7,
  a.sld_m8,
  a.sld_m9,
  a.sld_m10,
  a.sld_m11,
  a.sld_m12,
  a.nro_miss06,
  a.nro_miss09,
  a.nro_miss12,

  a.saldo_vig_m0,
  a.sld_cons_m0,
  a.sld_reactiva,
  a.clasificacion_m0,
  a.dm_fm0,
  a.saldo_ref_m0,
  a.saldo_jud_mo,
  a.saldo_cast_mo,
  a.saldo_rest_mo,

  a.saldo_vig_m2,
  a.clasificacion_m2,
  a.dm_org_m2,
  a.saldo_ref_m2,
  a.saldo_jud_m2,
  a.saldo_cast_m2,
  a.saldo_rest_m2,

  c.saldo_novig_neg_1um,
  c.saldo_novig_neg_1um_m2,
  c.saldo_nonormal_1um,
  c.saldo_nonormal_1um_m2,
  c.saldo_novig_neg_12um,
  c.saldo_novig_neg_12um_v2,
  c.sld_castigado_12um_rl,
  c.sld_castigado_12um_rl_v2,

  c.fec_nacimiento,
  c.fec_nacimiento_rl_min,
  c.fec_nacimiento_rl_max,

  a.dias_atraso_6m,
  a.dias_atraso_9m,
  a.dias_atraso_12m,
  a.jud_06um,
  a.jud_09um,
  a.jud_12um,
  a.cast_06um,
  a.cast_09um,
  a.cast_12um,
  a.ref_06um,
  a.ref_09um,
  a.ref_12um,
  a.ree_06um,
  a.ree_09um,
  a.ree_12um,
  a.ven_06um,
  a.ven_09um,
  a.ven_12um,

  CASE WHEN date_format(date_parse(a.codmes,'%Y%m') + interval '6' month,'%Y%m') > '202606' THEN null
       WHEN a.dias_atraso_6m  > 90 OR a.jud_06um = 1 OR a.cast_06um = 1 OR a.ref_06um = 1 OR a.ree_06um = 1 THEN 1 ELSE 0 END AS target_06m,
  CASE WHEN date_format(date_parse(a.codmes,'%Y%m') + interval '9' month,'%Y%m') > '202606' THEN null
       WHEN a.dias_atraso_9m  > 90 OR a.jud_09um = 1 OR a.cast_09um = 1 OR a.ref_09um = 1 OR a.ree_09um = 1 THEN 1 ELSE 0 END AS target_09m,
  CASE WHEN date_format(date_parse(a.codmes,'%Y%m') + interval '12' month,'%Y%m') > '202606' THEN null
       WHEN a.dias_atraso_12m > 90 OR a.jud_12um = 1 OR a.cast_12um = 1 OR a.ref_12um = 1 OR a.ree_12um = 1 THEN 1 ELSE 0 END AS target_12m,
  CASE WHEN date_format(date_parse(a.codmes,'%Y%m') + interval '1' month,'%Y%m') > '202606' THEN null
       WHEN a.dias_atraso_1m > 90 OR a.jud_01um = 1 OR a.cast_01um = 1 OR a.ref_01um = 1 OR a.ree_01um = 1 THEN 1 ELSE 0 END AS target_01m,
  CASE WHEN date_format(date_parse(a.codmes,'%Y%m') + interval '2' month,'%Y%m') > '202606' THEN null
       WHEN a.dias_atraso_2m > 90 OR a.jud_02um = 1 OR a.cast_02um = 1 OR a.ref_02um = 1 OR a.ree_02um = 1 THEN 1 ELSE 0 END AS target_02m,
  CASE WHEN date_format(date_parse(a.codmes,'%Y%m') + interval '3' month,'%Y%m') > '202606' THEN null
       WHEN a.dias_atraso_3m > 90 OR a.jud_03um = 1 OR a.cast_03um = 1 OR a.ref_03um = 1 OR a.ree_03um = 1 THEN 1 ELSE 0 END AS target_03m,
  CASE WHEN date_format(date_parse(a.codmes,'%Y%m') + interval '4' month,'%Y%m') > '202606' THEN null
       WHEN a.dias_atraso_4m > 90 OR a.jud_04um = 1 OR a.cast_04um = 1 OR a.ref_04um = 1 OR a.ree_04um = 1 THEN 1 ELSE 0 END AS target_04m,
  CASE WHEN date_format(date_parse(a.codmes,'%Y%m') + interval '5' month,'%Y%m') > '202606' THEN null
       WHEN a.dias_atraso_5m > 90 OR a.jud_05um = 1 OR a.cast_05um = 1 OR a.ref_05um = 1 OR a.ree_05um = 1 THEN 1 ELSE 0 END AS target_05m,
  CASE WHEN date_format(date_parse(a.codmes,'%Y%m') + interval '7' month,'%Y%m') > '202606' THEN null
       WHEN a.dias_atraso_7m > 90 OR a.jud_07um = 1 OR a.cast_07um = 1 OR a.ref_07um = 1 OR a.ree_07um = 1 THEN 1 ELSE 0 END AS target_07m,
  CASE WHEN date_format(date_parse(a.codmes,'%Y%m') + interval '8' month,'%Y%m') > '202606' THEN null
       WHEN a.dias_atraso_8m > 90 OR a.jud_08um = 1 OR a.cast_08um = 1 OR a.ref_08um = 1 OR a.ree_08um = 1 THEN 1 ELSE 0 END AS target_08m,
  CASE WHEN date_format(date_parse(a.codmes,'%Y%m') + interval '10' month,'%Y%m') > '202606' THEN null
       WHEN a.dias_atraso_10m > 90 OR a.jud_10um = 1 OR a.cast_10um = 1 OR a.ref_10um = 1 OR a.ree_10um = 1 THEN 1 ELSE 0 END AS target_10m,
  CASE WHEN date_format(date_parse(a.codmes,'%Y%m') + interval '11' month,'%Y%m') > '202606' THEN null
       WHEN a.dias_atraso_11m > 90 OR a.jud_11um = 1 OR a.cast_11um = 1 OR a.ref_11um = 1 OR a.ree_11um = 1 THEN 1 ELSE 0 END AS target_11m,

  a.flg_garantia,
  CASE
      WHEN a.flg_reactiva = 0 AND a.flg_solo_reactiva = 0 THEN 'SOLO NEGOCIO'
      WHEN a.flg_reactiva = 1 AND a.flg_solo_reactiva = 0 THEN 'MIXTO'
      WHEN a.flg_reactiva = 1 AND a.flg_solo_reactiva = 1 THEN 'REACTIVA'
      ELSE 'SIN DEUDA'
  END AS segmento_reactiva,
  a.flg_reactiva,
  a.flg_solo_reactiva,
  a.flag_cons,
  c.tipo_personeria,
  c.estado,
  c.ciiu,
  c.ubigeo,
  c.cl_estado,
  c.cl_tpoemp,
  c.giro_restringido,
  c.ubigeo_restringido,
  c.flag_bpe_v1,
  c.flag_bpe_v2,
  c.flag_bpe_parcial,
  c.flagcruce_cny,
  c.flagcruce,

  CASE
      WHEN a.saldo_cast_mo IS NOT NULL THEN 'CASTIGADO_ORIGEN'
      WHEN a.saldo_jud_mo  IS NOT NULL THEN 'JUDICIAL_ORIGEN'
      WHEN a.saldo_rest_mo IS NOT NULL THEN 'REESTRUCTURADO_ORIGEN'
      WHEN a.saldo_ref_m0  IS NOT NULL THEN 'REFINANCIADO_ORIGEN'
      WHEN a.clasificacion_m0 NOT IN ('0') THEN 'CLASIF_NO_NORMAL'
      WHEN c.flag_bpe_parcial NOT IN ('23. Ubigeo Restringido','99. Sin Caida') THEN 'NO_BPE'
      WHEN a.dm_fm0 > 0 THEN 'CON_DIASATRASO_ORIGEN'
      WHEN c.flagcruce = 'Cruce' OR c.flagcruce_cny = 'Cruce' THEN 'ESPECIALES'
      WHEN date_format(date_parse(a.codmes,'%Y%m') + interval '6' month,'%Y%m') > '202606' THEN 'INMADURO'
      WHEN a.nro_miss06 = 6 THEN 'SIN_INFORMACION'
      WHEN a.nro_miss06 > 3 THEN 'INSUFICIENTE'
      WHEN a.dias_atraso_6m > 90 OR a.jud_06um = 1 OR a.cast_06um = 1 OR a.ref_06um = 1 OR a.ree_06um = 1 THEN 'MALO'
      WHEN a.dias_atraso_6m <= 90 AND a.dias_atraso_6m > 30 THEN 'INDETERMINADO'
      ELSE 'BUENO'
  END AS flag_malo_06m,
  CASE
      WHEN a.saldo_cast_mo IS NOT NULL THEN 'CASTIGADO_ORIGEN'
      WHEN a.saldo_jud_mo  IS NOT NULL THEN 'JUDICIAL_ORIGEN'
      WHEN a.saldo_rest_mo IS NOT NULL THEN 'REESTRUCTURADO_ORIGEN'
      WHEN a.saldo_ref_m0  IS NOT NULL THEN 'REFINANCIADO_ORIGEN'
      WHEN a.clasificacion_m0 NOT IN ('0') THEN 'CLASIF_NO_NORMAL'
      WHEN c.flag_bpe_parcial NOT IN ('23. Ubigeo Restringido','99. Sin Caida') THEN 'NO_BPE'
      WHEN a.dm_fm0 > 0 THEN 'CON_DIASATRASO_ORIGEN'
      WHEN c.flagcruce = 'Cruce' OR c.flagcruce_cny = 'Cruce' THEN 'ESPECIALES'
      WHEN date_format(date_parse(a.codmes,'%Y%m') + interval '9' month,'%Y%m') > '202606' THEN 'INMADURO'
      WHEN a.nro_miss09 = 9 THEN 'SIN_INFORMACION'
      WHEN a.nro_miss09 > 4 THEN 'INSUFICIENTE'
      WHEN a.dias_atraso_9m > 90 OR a.jud_09um = 1 OR a.cast_09um = 1 OR a.ref_09um = 1 OR a.ree_09um = 1 THEN 'MALO'
      WHEN a.dias_atraso_9m <= 90 AND a.dias_atraso_9m > 30 THEN 'INDETERMINADO'
      ELSE 'BUENO'
  END AS flag_malo_09m,
  CASE
      WHEN a.saldo_cast_mo IS NOT NULL THEN 'CASTIGADO_ORIGEN'
      WHEN a.saldo_jud_mo  IS NOT NULL THEN 'JUDICIAL_ORIGEN'
      WHEN a.saldo_rest_mo IS NOT NULL THEN 'REESTRUCTURADO_ORIGEN'
      WHEN a.saldo_ref_m0  IS NOT NULL THEN 'REFINANCIADO_ORIGEN'
      WHEN a.clasificacion_m0 NOT IN ('0') THEN 'CLASIF_NO_NORMAL'
      WHEN c.flag_bpe_parcial NOT IN ('23. Ubigeo Restringido','99. Sin Caida') THEN 'NO_BPE'
      WHEN a.dm_fm0 > 0 THEN 'CON_DIASATRASO_ORIGEN'
      WHEN c.flagcruce = 'Cruce' OR c.flagcruce_cny = 'Cruce' THEN 'ESPECIALES'
      WHEN date_format(date_parse(a.codmes,'%Y%m') + interval '12' month,'%Y%m') > '202606' THEN 'INMADURO'
      WHEN a.nro_miss12 = 12 THEN 'SIN_INFORMACION'
      WHEN a.nro_miss12 > 6 THEN 'INSUFICIENTE'
      WHEN a.dias_atraso_12m > 90 OR a.jud_12um = 1 OR a.cast_12um = 1 OR a.ref_12um = 1 OR a.ree_12um = 1 THEN 'MALO'
      WHEN a.dias_atraso_12m <= 90 AND a.dias_atraso_12m > 30 THEN 'INDETERMINADO'
      ELSE 'BUENO'
  END AS flag_malo_12m,

  CASE WHEN b.probabilidad IS NULL THEN 1 ELSE 0 END AS falla_sin_score,
  CASE WHEN count(1) OVER (PARTITION BY a.codmes, a.tip_doc, a.key_value) > 1 THEN 1 ELSE 0 END AS falla_score_dup,
  CASE WHEN b.probabilidad IS NOT NULL
        AND (TRY_CAST(b.probabilidad AS double) IS NULL
             OR TRY_CAST(b.probabilidad AS double) < 0
             OR TRY_CAST(b.probabilidad AS double) > 1) THEN 1 ELSE 0 END AS falla_pd_rango,
  CASE WHEN a.ent_alta IS NULL THEN 1 ELSE 0 END AS falla_sin_entidad_alta,
  CASE WHEN date_format(date_parse(a.codmes,'%Y%m') + interval '12' month,'%Y%m') > '202606' THEN 1 ELSE 0 END AS falla_madurez_12m,
  CASE WHEN a.nro_miss12 = 12 THEN 1 ELSE 0 END AS falla_sin_rcc_futuro,
  CASE WHEN date_format(date_parse(a.codmes,'%Y%m') + interval '12' month,'%Y%m') <= '202606'
        AND a.dias_atraso_12m IS NULL AND a.jud_12um IS NULL AND a.cast_12um IS NULL
        AND a.ref_12um IS NULL AND a.ree_12um IS NULL THEN 1 ELSE 0 END AS falla_target_nulo
FROM disc_model_owner.ds_adm_bpe_bankbn_tmp_mad_rcc_t5 a
LEFT JOIN disc_model_owner.ds_adm_bpe_bankbn_tmp_mad_bpe_t5 c
    ON a.codmes = c.codmes
   AND a.tip_doc = c.tip_doc
   AND a.key_value = c.key_value
LEFT JOIN score b
    ON a.tip_doc = b.tip_doc
   AND a.key_value = b.key_value
   AND a.codmes = date_format(date_parse(b.p_codmes,'%Y%m') + interval '1' month,'%Y%m')
