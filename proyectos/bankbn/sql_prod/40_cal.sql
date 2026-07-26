-- 40. CAL -> disc_model_owner.ds_adm_bpe_bankbn_cal
-- 40.1 base ds_adm_bpe_bankbn_drivers, ventana A12 codmes 202206-202506
-- 40.2 filtro_<id> = 1 cae en el filtro / 0 pasa; uno por cada id de caso_filtros.signed.yaml
-- 40.3 CASO3 -> 99 | pd_raw NULL -> 98 | CASO2 (a m-2) + honesta -> 0 | CASO1 solo marca
-- 40.4 filtro_perfil_empresa, filtro_deuda_comercial, filtro_ent_honrada, filtro_alta,
--      filtro_monto_endeud y filtro_saldo_vig_m0 = 0: aplicados en 10_po / 20_mad
CREATE TABLE disc_model_owner.ds_adm_bpe_bankbn_cal AS
WITH ent AS (
    SELECT
        d.*,
        CASE
            WHEN UPPER(COALESCE(d.nombre_instit_financiera,'')) LIKE 'BBVA CONSUMER%' THEN 'OTRO'
            WHEN d.cod_instit_financiera = '00002' THEN 'IBK'
            WHEN UPPER(COALESCE(d.nombre_instit_financiera,'')) LIKE '%CREDITO DEL PERU%' THEN 'BCP'
            WHEN UPPER(COALESCE(d.nombre_instit_financiera,'')) LIKE '%BBVA%' THEN 'BBVA'
            WHEN UPPER(COALESCE(d.nombre_instit_financiera,'')) LIKE '%CONTINENTAL%' THEN 'BBVA'
            WHEN UPPER(COALESCE(d.nombre_instit_financiera,'')) LIKE '%SCOTIABANK%' THEN 'SCOTIA'
            ELSE 'OTRO'
        END AS entidad
    FROM disc_model_owner.ds_adm_bpe_bankbn_drivers d
    WHERE d.codmes BETWEEN '202206' AND '202506'
),
base AS (
    SELECT
        d.codmes,
        d.tip_doc,
        d.key_value,
        d.cod_instit_financiera,

        d.target_06m,
        d.target_09m,
        d.target_12m,

        TRY_CAST(d.probabilidad AS DOUBLE) AS pd_raw,

        CASE WHEN COALESCE(d.flg_ppjj,0) = 1 THEN 1 ELSE 0 END AS flg_ppjj,
        CASE WHEN COALESCE(d.flg_impulsa,0) = 1 THEN 1 ELSE 0 END AS flg_impulsa,
        CASE WHEN COALESCE(d.flg_impulsa_u12m,0) = 1 THEN 1 ELSE 0 END AS flg_impulsa_u12m,
        d.flag_bpe_parcial,
        d.entidad,
        COALESCE(d.segmento_reactiva,'SIN DEUDA') AS segmento_reactiva,

        CAST(0 AS INTEGER) AS filtro_perfil_empresa,
        CAST(0 AS INTEGER) AS filtro_deuda_comercial,
        CAST(0 AS INTEGER) AS filtro_ent_honrada,
        CASE WHEN COALESCE(d.nombre_instit_financiera,'VALOR NO ENVIADO POR IBK') IN (
                    'BANCO AGROPECUARIO',
                    'BANCO DE LA NACION',
                    'CAJA RURAL DE AHORRO Y CREDITO SIPAN S A',
                    'LEASING TOTAL S A',
                    'VALOR NO ENVIADO POR IBK')
                  OR UPPER(COALESCE(d.nombre_instit_financiera,'')) LIKE 'BBVA CONSUMER%'
             THEN 1 ELSE 0 END AS filtro_excl_entidades,
        CAST(0 AS INTEGER) AS filtro_alta,
        CAST(0 AS INTEGER) AS filtro_monto_endeud,
        CAST(0 AS INTEGER) AS filtro_saldo_vig_m0,
        CASE WHEN COALESCE(d.tipo_personeria,'') = 'PPNN_SN' THEN 1 ELSE 0 END AS filtro_pnsn,
        CASE WHEN d.entidad IN ('BCP','BBVA','SCOTIA','IBK') THEN 0 ELSE 1 END AS filtro_top4,
        CASE WHEN COALESCE(d.segmento_reactiva,'') = 'REACTIVA' THEN 1 ELSE 0 END AS filtro_reactiva_puro,
        CASE WHEN COALESCE(d.flg_impulsa_u12m,0) = 1 THEN 1 ELSE 0 END AS filtro_impulsa_u12m,
        CASE WHEN COALESCE(d.flg_impulsa,0) = 1 THEN 1 ELSE 0 END AS filtro_impulsa_m0,

        CASE WHEN d.saldo_cast_m2 IS NOT NULL THEN 1 ELSE 0 END AS filtro_castigado_org,
        CASE WHEN d.saldo_jud_m2  IS NOT NULL THEN 1 ELSE 0 END AS filtro_judicial_org,
        CASE WHEN d.saldo_rest_m2 IS NOT NULL THEN 1 ELSE 0 END AS filtro_reest_org,
        CASE WHEN d.saldo_ref_m2  IS NOT NULL THEN 1 ELSE 0 END AS filtro_refin_org,
        CASE WHEN COALESCE(d.clasificacion_m2,'0') <> '0' THEN 1 ELSE 0 END AS filtro_clasif_no_normal,
        CASE WHEN COALESCE(d.dm_org_m2,0) > 0 THEN 1 ELSE 0 END AS filtro_diasatraso_org,
        CASE WHEN COALESCE(d.saldo_nonormal_1um_m2,0) > 0 THEN 1 ELSE 0 END AS filtro_sbs_no_normal_1um,
        CASE WHEN COALESCE(d.saldo_novig_neg_1um_m2,0) > 0 THEN 1 ELSE 0 END AS filtro_novig_1um,

        CASE WHEN COALESCE(CAST(SUBSTRING(d.codmes,1,4) AS INT) - CAST(EXTRACT(YEAR FROM d.fec_nacimiento) AS INT), 30) <= 25
                  OR COALESCE(CAST(SUBSTRING(d.codmes,1,4) AS INT) - CAST(EXTRACT(YEAR FROM d.fec_nacimiento) AS INT), 30) >= 75
             THEN 1 ELSE 0 END AS filtro_edad_titular,
        CASE WHEN COALESCE(CAST(SUBSTRING(d.codmes,1,4) AS INT) - CAST(EXTRACT(YEAR FROM d.fec_nacimiento_rl_max) AS INT), 30) <= 25
                  OR COALESCE(CAST(SUBSTRING(d.codmes,1,4) AS INT) - CAST(EXTRACT(YEAR FROM d.fec_nacimiento_rl_min) AS INT), 30) >= 75
             THEN 1 ELSE 0 END AS filtro_edad_rrll,
        CASE WHEN COALESCE(d.saldo_novig_neg_12um_v2,0) > 0 THEN 1 ELSE 0 END AS filtro_novig_12um,
        CASE WHEN COALESCE(d.sld_castigado_12um_rl_v2,0) > 0 THEN 1 ELSE 0 END AS filtro_rrll_cast_12um,

        CASE WHEN COALESCE(d.flag_bpe_parcial,'') = '20. Estado Diferente A' THEN 1 ELSE 0 END AS filtro_sunat_estado,
        CASE WHEN COALESCE(d.flag_bpe_parcial,'') = '22. Giro Restringido' THEN 1 ELSE 0 END AS filtro_sunat_giro,
        CASE WHEN COALESCE(d.flag_bpe_parcial,'') = '23. Ubigeo Restringido' THEN 1 ELSE 0 END AS filtro_sunat_ubigeo,
        CASE WHEN COALESCE(d.flagcruce,'') = 'Cruce' OR COALESCE(d.flagcruce_cny,'') = 'Cruce' THEN 1 ELSE 0 END AS filtro_especiales,
        CASE WHEN COALESCE(d.dias_atraso_12m,0) > 30 AND COALESCE(d.dias_atraso_12m,0) <= 90 THEN 1 ELSE 0 END AS filtro_indeterminado,
        CASE WHEN COALESCE(d.flag_malo_12m,'') IN ('SIN_INFORMACION','INSUFICIENTE') THEN 1 ELSE 0 END AS filtro_madurez_blanda,

        CASE WHEN d.probabilidad IS NULL THEN 1 ELSE 0 END AS falla_pd_raw,
        CASE WHEN d.cod_instit_financiera IS NULL THEN 1 ELSE 0 END AS falla_entidad,
        CASE WHEN d.entidad = 'OTRO' AND d.cod_instit_financiera IS NOT NULL THEN 1 ELSE 0 END AS falla_entidad_sin_mapa,
        CASE WHEN d.target_12m IS NULL THEN 1 ELSE 0 END AS falla_target_12m,
        CASE WHEN CAST(DATE_FORMAT(DATE_ADD('month',12,DATE_PARSE(d.codmes,'%Y%m')),'%Y%m') AS INT) > 202606 THEN 1 ELSE 0 END AS falla_madurez,
        CASE WHEN COUNT(1) OVER (PARTITION BY d.codmes, d.tip_doc, d.key_value) > 1 THEN 1 ELSE 0 END AS falla_dup
    FROM ent d
)
SELECT
    b.*,
    CASE
        WHEN b.filtro_perfil_empresa + b.filtro_deuda_comercial + b.filtro_ent_honrada + b.filtro_excl_entidades
           + b.filtro_alta + b.filtro_monto_endeud + b.filtro_saldo_vig_m0 + b.filtro_pnsn + b.filtro_top4
           + b.filtro_reactiva_puro + b.filtro_impulsa_u12m + b.filtro_impulsa_m0 > 0 THEN 99
        WHEN b.pd_raw IS NULL THEN 98
        WHEN b.filtro_castigado_org + b.filtro_judicial_org + b.filtro_reest_org + b.filtro_refin_org
           + b.filtro_clasif_no_normal + b.filtro_diasatraso_org + b.filtro_sbs_no_normal_1um + b.filtro_novig_1um
           + b.filtro_edad_titular + b.filtro_edad_rrll + b.filtro_novig_12um + b.filtro_rrll_cast_12um = 0 THEN 1
        ELSE 0
    END AS flg_clean
FROM base b
