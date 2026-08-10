-- 6a_scr_calibrado.sql | PD calibrada y puntuacion sobre la FUENTE DEL SCORE, p_codmes 202206-202607. personeria sale de tip_doc, fhat va embebido por trimestre del codmes_alta = p_codmes+1. Particionada por p_codmes: son ~4.5M filas por mes
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
    SELECT CAST(tip_doc AS VARCHAR)                                          AS tip_doc,
           key_value,
           CAST(p_codmes AS INT)                                             AS pm,
           max(TRY_CAST(probabilidad AS DOUBLE))                             AS pd_raw
    FROM e_perm_aws.scr_admbankbpe_rsk
    WHERE p_codmes BETWEEN '202206' AND '202607'
    GROUP BY CAST(tip_doc AS VARCHAR), key_value, CAST(p_codmes AS INT)
),
c AS (
    SELECT b.tip_doc, b.key_value, b.pm, b.pd_raw,
           CASE WHEN b.tip_doc = '2' THEN 'PJJ' ELSE 'PNN' END               AS personeria,
           CAST(DATE_FORMAT(DATE_ADD('month', 1, DATE_PARSE(CAST(b.pm AS VARCHAR), '%Y%m')), '%Y%m') AS INT) AS codmes_alta,
           greatest(1e-6, least(1 - 1e-6, b.pd_raw))                         AS p
    FROM b
    WHERE b.pd_raw IS NOT NULL
),
n AS (
    SELECT c.*, f.fhat,
           greatest(1e-6, least(1 - 1e-6,
             CASE WHEN c.personeria = 'PNN'
                  THEN 1.0 / (1.0 + exp(-( -0.66018848026577570 + 0.59389236895322650 * ln(c.p) + 0.10766439295961687 * ln(1.0 - c.p) )))
                  ELSE 1.0 / (1.0 + exp(-( -0.15993259962662906 + 0.96753989187205014 * (ln(c.p) - ln(1.0 - c.p)) )))
             END )) AS pd_cal
    FROM c
    LEFT JOIN ft f
      ON f.trim_ft = (c.codmes_alta / 100) * 10 + ((mod(c.codmes_alta, 100) - 1) / 3 + 1)
),
r AS (
    SELECT n.*,
           greatest(0.001, least(0.999,
             0.03597881726832541 * ( 0.03 * ((1 - exp(-35 * n.pd_cal)) / (1 - exp(-35.0)))
                        + 0.16 * (1 - (1 - exp(-35 * n.pd_cal)) / (1 - exp(-35.0))) )
             / CASE WHEN n.personeria = 'PNN' THEN 0.03424207361820211 ELSE 0.03868433725325406 END )) AS rho_i
    FROM n
)
SELECT r.tip_doc,
       r.key_value,
       r.codmes_alta,
       r.personeria,
       r.pd_raw                                            AS prob_modelo,
       r.pd_cal,
       r.rho_i,
       r.fhat,
       greatest(1e-6, least(1 - 1e-6,
         normal_cdf(0, 1, (inverse_normal_cdf(0, 1, r.pd_cal)
                           - sqrt(r.rho_i) * 0.34999999999999998 * r.fhat) / sqrt(1.0 - r.rho_i))
         * CASE WHEN r.personeria = 'PNN' THEN 1.16299104583772395 ELSE 1.13685059874822714 END )) AS prob_modelo_cal,
       CAST(round((1.0 - greatest(1e-6, least(1 - 1e-6,
         normal_cdf(0, 1, (inverse_normal_cdf(0, 1, r.pd_cal)
                           - sqrt(r.rho_i) * 0.34999999999999998 * r.fhat) / sqrt(1.0 - r.rho_i))
         * CASE WHEN r.personeria = 'PNN' THEN 1.16299104583772395 ELSE 1.13685059874822714 END ))) * 1000) AS INTEGER) AS puntuacion_modelo,
       CAST(1 AS INTEGER)                                  AS flg_clean,
       'SIN_FLAGS_DEFAULT_CLEAN'                           AS flg_clean_fuente,
       CAST(r.pm AS VARCHAR)                               AS p_codmes
FROM r
