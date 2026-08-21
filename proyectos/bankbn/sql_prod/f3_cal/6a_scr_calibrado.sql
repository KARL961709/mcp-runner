-- 6a_scr_calibrado.sql | scr_admbankbpe_rsk COMPLETA mas tres columnas de calibracion. Una fila de entrada, una de salida: no deduplica. flg_clean va en 1 porque no hay tabla de flags con los 13 criterios ex-ante, y con bloque unico no afecta la PD
CREATE TABLE disc_model_owner.scr_admbankbpe_calibrado_202607
WITH (format = 'PARQUET', parquet_compression = 'SNAPPY', partitioned_by = ARRAY['p_codmes']) AS
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
         (20262, 0.81754407362480930),
         (20263, -0.03459445072099430)
),
b AS (
    SELECT a.*,
           greatest(1e-6, least(1 - 1e-6, TRY_CAST(a.probabilidad AS DOUBLE)))  AS p,
           (CAST(DATE_FORMAT(DATE_ADD('month', 1, DATE_PARSE(CAST(a.p_codmes AS VARCHAR), '%Y%m')), '%Y') AS INT)) * 10
             + ((CAST(DATE_FORMAT(DATE_ADD('month', 1, DATE_PARSE(CAST(a.p_codmes AS VARCHAR), '%Y%m')), '%m') AS INT) - 1) / 3 + 1) AS trim_c
    FROM e_perm_aws.scr_admbankbpe_rsk a
    WHERE a.p_codmes BETWEEN '202206' AND '202607'
      AND a.probabilidad IS NOT NULL
),
n AS (
    SELECT b.*, f.fhat,
           greatest(1e-6, least(1 - 1e-6,
             CASE WHEN b.tip_doc = '2'
                  THEN 1.0 / (1.0 + exp(-( -0.15993259962662906 + 0.96753989187205014 * (ln(b.p) - ln(1.0 - b.p)) )))
                  ELSE 1.0 / (1.0 + exp(-( -0.66018848026577570 + 0.59389236895322650 * ln(b.p) + 0.10766439295961687 * ln(1.0 - b.p) )))
             END )) AS pd_cal
    FROM b
    LEFT JOIN ft f ON f.trim_ft = b.trim_c
),
s AS (
    SELECT n.*,
           greatest(0.001, least(0.999,
             0.03597881726832541 * ( 0.03 * ((1 - exp(-35 * n.pd_cal)) / (1 - exp(-35.0)))
                        + 0.16 * (1 - (1 - exp(-35 * n.pd_cal)) / (1 - exp(-35.0))) )
             / CASE WHEN n.tip_doc = '2' THEN 0.03868433725325406 ELSE 0.03424207361820211 END )) AS rho_i
    FROM n
)
SELECT s.codmes,
       s.tip_doc,
       s.key_value,
       s.puntuacion,
       s.probabilidad,
       s.modelo,
       s.fec_replica,
       s.segmento,
       s.var1,
       s.var2,
       s.var3,
       s.var4,
       s.var5,
       s.woe_beta_sldoppcomer,
       s.woe_prm_decresldo12m,
       s.woe_nro_decresldo12m,
       s.woe_beta_nroenti,
       s.woe_max_nrocredsldo06m,
       s.woe_prm_porcsldoimpa12m,
       s.woe_peor_clasicony09m,
       s.woe_prm_decresldopp12m,
       s.woe_prm_usotcfueraibk12m,
       s.woe_prm_decresldotc12m,
       s.woe_beta_sldopp12m,
       s.woe_max_dismsldonoprinc12m,
       s.woe_max_nroentinegocny06m,
       s.woe_nro_mesesatrasmay8dias09m,
       s.woe_max_dismsldoretail03m,
       s.woe_beta_sldotc12m,
       s.woe_rat_sldo09msobre12mrl,
       s.woe_max_diasatras09mrl,
       s.woe_nro_dismsaldonormal12mcny,
       s.woe_max_dismsldo12rl,
       s.woe_nro_mesesdismsldoretail12m,
       s.woe_rat_sldonormal3msobre12mrl,
       s.woe_porc_messldogiro06m,
       s.woe_prm_ratdispefect03m,
       s.woe_nro_mesesdicmsldoprinc12m,
       s.woe_prm_valorexpimp12m,
       s.woe_min_sldopasi06m,
       s.woe_cant_entireportsisnoreg,
       s.woe_prm_deudatelco12m,
       s.woe_cant_vehi,
       s.woe_anti_negmeses,
       s.woe_prm_nrotrxcashout06m,
       s.woe_nro_mesescastin06m,
       s.woe_edad,
       s.woe_dpt_grupo_v2,
       s.woe_ciiu_grupo_v2,
       s.rat_promsldnegdecreprin3y6m,
       s.rat_promsldnegdecre03y06m,
       s.woe_avg_porcsald_otrasent12m,
       greatest(1e-6, least(1 - 1e-6,
        normal_cdf(0, 1, (inverse_normal_cdf(0, 1, s.pd_cal)
                          - sqrt(s.rho_i) * 0.34999999999999998 * s.fhat) / sqrt(1.0 - s.rho_i))
        * CASE WHEN s.tip_doc = '2' THEN 1.13685059874822714 ELSE 1.16299104583772395 END ))                                                                AS prob_modelo_cal,
       CAST(round((1.0 - greatest(1e-6, least(1 - 1e-6,
        normal_cdf(0, 1, (inverse_normal_cdf(0, 1, s.pd_cal)
                          - sqrt(s.rho_i) * 0.34999999999999998 * s.fhat) / sqrt(1.0 - s.rho_i))
        * CASE WHEN s.tip_doc = '2' THEN 1.13685059874822714 ELSE 1.16299104583772395 END ))) * 1000) AS INTEGER)                                           AS puntuacion_modelo,
       CAST(1 AS INTEGER)                                                       AS flg_clean,
       s.p_codmes
FROM s
