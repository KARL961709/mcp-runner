-- 5b_cal_scored.sql | agrega prob_modelo_cal (pd_pit), puntuacion_modelo y flg_clean binario 0/1. Sufijo 202607 = mes de proceso, el dato llega a 202606. Coeficientes ajustados SOLO con IBK: la PD de las otras 3 entidades es comparativa
CREATE TABLE disc_model_owner.ds_adm_bpe_bankbn_cal_202607
WITH (format = 'PARQUET', parquet_compression = 'SNAPPY') AS
WITH ft (trim_ft, fhat) AS (
    VALUES (20222, 0.74132125871317922),
         (20223, -0.38935742968535247),
         (20224, -0.92891552347195483),
         (20231, -1.06092313681836292),
         (20232, -1.15686885926677885),
         (20233, -0.03010354442788290),
         (20234, 0.68472846461918047),
         (20241, 1.20449272519235961),
         (20242, 1.10475120261055704),
         (20243, 1.10024522011903247),
         (20244, 1.45959145865182061),
         (20251, 1.54673705001372630),
         (20252, 2.01943144365660565),
         (20253, 2.01943144365660565),
         (20254, 2.01943144365660565),
         (20261, 2.01943144365660565),
         (20262, 0.81754407362480930)
),
b AS (
    SELECT c.*,
           CASE WHEN COALESCE(c.flg_ppjj,0) = 1 THEN 'PJJ' ELSE 'PNN' END AS personeria,
           CAST(SUBSTRING(c.codmes,1,4) AS INT) * 10
             + ((CAST(SUBSTRING(c.codmes,5,2) AS INT) - 1) / 3 + 1)       AS trim_c,
           greatest(1e-6, least(1 - 1e-6, TRY_CAST(c.pd_raw AS DOUBLE)))  AS p
    FROM disc_model_owner.ds_adm_bpe_bankbn_cal c
),
niv AS (
    SELECT b.*, f.fhat,
           greatest(1e-6, least(1 - 1e-6,
             CASE WHEN b.personeria = 'PNN'
                  THEN 1.0 / (1.0 + exp(-( -0.65687342292803830 + 0.59875703554922588 * ln(b.p) + 0.07094297192462927 * ln(1.0 - b.p) )))
                  ELSE 1.0 / (1.0 + exp(-( -0.11970310819429554 + 0.97984738934227134 * (ln(b.p) - ln(1.0 - b.p)) )))
             END )) AS pd_cal
    FROM b
    LEFT JOIN ft f ON f.trim_ft = b.trim_c
),
rho AS (
    SELECT n.*,
           greatest(0.001, least(0.999,
             0.03597881726832541 * ( 0.03 * ((1 - exp(-35 * n.pd_cal)) / (1 - exp(-35.0)))
                         + 0.16 * (1 - (1 - exp(-35 * n.pd_cal)) / (1 - exp(-35.0))) )
             / CASE WHEN n.personeria = 'PNN' THEN 0.03429261520706808 ELSE 0.03891832914207297 END )) AS rho_i
    FROM niv n
),
pit AS (
    SELECT r.*,
           greatest(1e-6, least(1 - 1e-6,
             normal_cdf(0, 1, (inverse_normal_cdf(0, 1, r.pd_cal)
                               - sqrt(r.rho_i) * 0.34999999999999998 * r.fhat) / sqrt(1.0 - r.rho_i))
             * CASE WHEN r.personeria = 'PNN' THEN 1.16330065495620971 ELSE 1.13781855024548495 END )) AS pd_pit
    FROM rho r
)
SELECT c.codmes,
       c.tip_doc,
       c.key_value,
       c.cod_instit_financiera,
       c.target_01m,
       c.target_02m,
       c.target_03m,
       c.target_04m,
       c.target_05m,
       c.target_06m,
       c.target_07m,
       c.target_08m,
       c.target_09m,
       c.target_10m,
       c.target_11m,
       c.target_12m,
       c.pd_raw,
       c.flg_ppjj,
       c.flg_impulsa,
       c.flg_impulsa_u12m,
       c.flag_bpe_parcial,
       c.entidad,
       c.segmento_reactiva,
       c.filtro_perfil_empresa,
       c.filtro_deuda_comercial,
       c.filtro_ent_honrada,
       c.filtro_excl_entidades,
       c.filtro_alta,
       c.filtro_monto_endeud,
       c.filtro_saldo_vig_m0,
       c.filtro_pnsn,
       c.filtro_top4,
       c.filtro_reactiva_puro,
       c.filtro_impulsa_u12m,
       c.filtro_impulsa_m0,
       c.filtro_castigado_org,
       c.filtro_judicial_org,
       c.filtro_reest_org,
       c.filtro_refin_org,
       c.filtro_clasif_no_normal,
       c.filtro_diasatraso_org,
       c.filtro_sbs_no_normal_1um,
       c.filtro_novig_1um,
       c.filtro_edad_titular,
       c.filtro_edad_rrll,
       c.filtro_novig_12um,
       c.filtro_rrll_cast_12um,
       c.filtro_sunat_estado,
       c.filtro_sunat_giro,
       c.filtro_sunat_ubigeo,
       c.filtro_especiales,
       c.filtro_indeterminado,
       c.filtro_madurez_blanda,
       c.falla_pd_raw,
       c.falla_entidad,
       c.falla_entidad_sin_mapa,
       c.falla_target_12m,
       c.falla_madurez,
       c.falla_dup,
       c.flg_clean                                        AS flg_clean_calib,
       c.flg_calib,
       c.pd_pit                                            AS prob_modelo_cal,
       CAST(round((1.0 - c.pd_pit) * 1000) AS INTEGER)     AS puntuacion_modelo,
       CASE WHEN c.filtro_pnsn
                 + c.filtro_castigado_org + c.filtro_judicial_org + c.filtro_reest_org + c.filtro_refin_org
                 + c.filtro_clasif_no_normal + c.filtro_diasatraso_org + c.filtro_sbs_no_normal_1um
                 + c.filtro_novig_1um + c.filtro_edad_titular + c.filtro_edad_rrll
                 + c.filtro_novig_12um + c.filtro_rrll_cast_12um = 0
            THEN 1 ELSE 0 END                               AS flg_clean,
       c.pd_cal, c.rho_i, c.fhat, c.personeria
FROM pit c
