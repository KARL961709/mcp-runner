-- =====================================================================================
-- I1 | V1 vs V2 cara a cara, MISMA poblacion, mismas exclusiones
--
--   V1  entrenado SOLO con clean -> esos coeficientes aplicados a TODOS (clean y dirty)
--   V2  cada bloque con sus propios coeficientes            (lo que esta en produccion)
--
-- POR QUE HACE FALTA
--   C1/C4 y mi analisis offline dieron respuestas distintas, pero estaban sobre
--   poblaciones distintas:
--       offline   11,597 altas · INCLUYE era Impulsa · EXCLUYE flg_impulsa por flag
--       C1/C4     10,871 altas · EXCLUYE era Impulsa · INCLUYE los flag-Impulsa
--   Son exclusiones cruzadas: no son comparables. Aqui se fija UNA sola poblacion.
--
-- POBLACION  altas IBK TOP4, 202207-202505 (12m cerrados),
--            EXCLUYENDO flg_impulsa=1 y flg_reactiva_puro=1 POR FLAG.
--            Es el criterio que uso la calibracion para el bloque dirty (q3b) y el
--            unico implementable ex-ante. La era NO se excluye por codmes.
--
-- SALIDA  por version x personeria x bloque, mas los totales:
--   n · defaults · rd_obs · pd_prom · EC · banda Jeffreys · dentro/fuera · veredicto
--
-- COMO SE LEE
--   * lo que descalifica una version es SUB-PREDECIR (pd < rd): emitir PD por debajo
--     del default observado. Se marca en `veredicto`.
--   * a igual ausencia de sub-prediccion, gana la que tenga EC mas chico Y mas
--     PAREJO entre personerias: un +39% en PJJ contra +7% en PNN significa que el
--     margen depende de si eres persona natural o juridica, que no es defendible.
-- READ-ONLY.
-- =====================================================================================

WITH ft (codmes_alta, fhat) AS ( VALUES
  (202207, 0.46731627731126968),
  (202208, 0.056728699947162099),
  (202209, -0.38935742968535247),
  (202210, -0.70072994178821002),
  (202211, -0.85205451520464348),
  (202212, -0.92891552347195483),
  (202301, -1.0159184358416815),
  (202302, -1.0379535945181364),
  (202303, -1.0609231368183629),
  (202304, -1.105625425606386),
  (202305, -1.1568688592667788),
  (202306, -1.1568688592667788),
  (202307, -0.94596279749778256),
  (202308, -0.51623687799565809),
  (202309, -0.030103544427882899),
  (202310, 0.32449026737520231),
  (202311, 0.52946365930378281),
  (202312, 0.68472846461918047),
  (202401, 0.88376877419346278),
  (202402, 1.0779696991599816),
  (202403, 1.2044927251923596),
  (202404, 1.201179762312532),
  (202405, 1.1457097080976519),
  (202406, 1.104751202610557),
  (202407, 1.1060161144381395),
  (202408, 1.1019902137713098),
  (202409, 1.1002452201190325),
  (202410, 1.1875559465718),
  (202411, 1.3180022720336295),
  (202412, 1.4595914586518206),
  (202501, 1.5193331146887308),
  (202502, 1.5295598659038827),
  (202503, 1.5467370500137263),
  (202504, 1.6703824334712063),
  (202505, 1.8720398724011265),
  (202506, 2.0194314436566057),
  (202507, 2.0194314436566057),
  (202508, 2.0194314436566057),
  (202509, 2.0194314436566057),
  (202510, 2.0194314436566057),
  (202511, 2.0194314436566057),
  (202512, 2.0194314436566057),
  (202601, 2.0194314436566057),
  (202602, 2.0194314436566057),
  (202603, 2.0194314436566057),
  (202604, 1.9724204666385832),
  (202605, 1.4715585841909371),
  (202606, 0.8175440736248093),
  (202607, 0.2008886726564256),
  (202608, -0.021384045860002102),
  (202609, -0.034594450720994298)
),
pdr AS (
  SELECT cast(tip_doc AS varchar) AS tip_doc, key_value, cast(p_codmes AS int) AS p_codmes,
         max(probabilidad) AS pd_raw
  FROM e_perm_aws.scr_admbankbpe_rsk
  WHERE p_codmes BETWEEN '202206' AND '202504'
  GROUP BY 1,2,3
),
base AS (
  SELECT cast(a.codmes AS int) AS codmes,
         CASE WHEN a.tip_doc='2' THEN 'PJJ' ELSE 'PNN' END AS personeria,
         a.flg_calib_m2 AS flg_clean, a.target_12m,
         greatest(1e-6, least(1-1e-6, p.pd_raw)) AS pd_raw, f.fhat
  FROM disc_model_owner.bnbpe_ibk_calib_src a
  JOIN pdr p ON p.tip_doc=cast(a.tip_doc AS varchar) AND p.key_value=a.key_value
            AND p.p_codmes = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m')
                                              - interval '1' month,'%Y%m') AS int)
  JOIN ft f ON f.codmes_alta = cast(a.codmes AS int)
  WHERE a.flg_ibk=1 AND a.top4_entidad='TOP4'
    AND cast(a.codmes AS int) BETWEEN 202207 AND 202505
    AND coalesce(a.flg_impulsa,0)       = 0
    AND coalesce(a.flg_reactiva_puro,0) = 0
),
cln AS (SELECT * FROM base WHERE flg_clean=1),
dty AS (SELECT * FROM base WHERE flg_clean=0),
niv_cln AS (
  SELECT b.*, greatest(1e-6, least(1-1e-6,
    CASE WHEN b.personeria='PNN' THEN 1.0/(1.0+exp(-( -0.72488396139167532 + 0.63943961553578943*ln(b.pd_raw) + -1.0325848544388896*ln(1.0-b.pd_raw) )))
         ELSE 1.0/(1.0+exp(-( 0.17759688908412222 + 1.058477056441401*(ln(b.pd_raw)-ln(1.0-b.pd_raw)) ))) END )) AS pd_cal
  FROM cln b ),
rho_cln AS (
  SELECT n.*, greatest(0.001, least(0.999,
    0.035978817268325414 * ( 0.03*((1-exp(-35*n.pd_cal))/(1-exp(-35.0))) + 0.16*(1-(1-exp(-35*n.pd_cal))/(1-exp(-35.0))) )
    / CASE WHEN n.personeria='PNN' THEN 0.035560752391369591 ELSE 0.03634808815365035 END )) AS rho_i
  FROM niv_cln n ),
pit_cln AS (
  SELECT r.*, greatest(1e-6, least(1-1e-6,
    normal_cdf(0,1,(inverse_normal_cdf(0,1,r.pd_cal) - sqrt(r.rho_i)*0.34999999999999998*r.fhat)/sqrt(1.0-r.rho_i))
    * CASE WHEN r.personeria='PNN' THEN 1.1306030131221239 ELSE 1.1073857212572329 END )) AS pd_pit
  FROM rho_cln r ),
niv_dty AS (
  SELECT b.*, greatest(1e-6, least(1-1e-6,
    CASE WHEN b.personeria='PNN' THEN 1.0/(1.0+exp(-( -0.15676765088130001 + 0.64162444955106612*ln(b.pd_raw) + 0.083173096581749414*ln(1.0-b.pd_raw) )))
         ELSE 1.0/(1.0+exp(-( -0.60971743608471285 + 0.85566792258078261*(ln(b.pd_raw)-ln(1.0-b.pd_raw)) ))) END )) AS pd_cal
  FROM dty b ),
rho_dty AS (
  SELECT n.*, greatest(0.001, least(0.999,
    0.035978817268325414 * ( 0.03*((1-exp(-35*n.pd_cal))/(1-exp(-35.0))) + 0.16*(1-(1-exp(-35*n.pd_cal))/(1-exp(-35.0))) )
    / CASE WHEN n.personeria='PNN' THEN 0.030343535251014398 ELSE 0.036801943015635719 END )) AS rho_i
  FROM niv_dty n ),
pit_dty AS (
  SELECT r.*, greatest(1e-6, least(1-1e-6,
    normal_cdf(0,1,(inverse_normal_cdf(0,1,r.pd_cal) - sqrt(r.rho_i)*0.34999999999999998*r.fhat)/sqrt(1.0-r.rho_i))
    * CASE WHEN r.personeria='PNN' THEN 1.0801021982671937 ELSE 1.1207211368581367 END )) AS pd_pit
  FROM rho_dty r ),
niv_xdty AS (
  SELECT b.*, greatest(1e-6, least(1-1e-6,
    CASE WHEN b.personeria='PNN' THEN 1.0/(1.0+exp(-( -0.72488396139167532 + 0.63943961553578943*ln(b.pd_raw) + -1.0325848544388896*ln(1.0-b.pd_raw) )))
         ELSE 1.0/(1.0+exp(-( 0.17759688908412222 + 1.058477056441401*(ln(b.pd_raw)-ln(1.0-b.pd_raw)) ))) END )) AS pd_cal
  FROM dty b ),
rho_xdty AS (
  SELECT n.*, greatest(0.001, least(0.999,
    0.035978817268325414 * ( 0.03*((1-exp(-35*n.pd_cal))/(1-exp(-35.0))) + 0.16*(1-(1-exp(-35*n.pd_cal))/(1-exp(-35.0))) )
    / CASE WHEN n.personeria='PNN' THEN 0.035560752391369591 ELSE 0.03634808815365035 END )) AS rho_i
  FROM niv_xdty n ),
pit_xdty AS (
  SELECT r.*, greatest(1e-6, least(1-1e-6,
    normal_cdf(0,1,(inverse_normal_cdf(0,1,r.pd_cal) - sqrt(r.rho_i)*0.34999999999999998*r.fhat)/sqrt(1.0-r.rho_i))
    * CASE WHEN r.personeria='PNN' THEN 1.1306030131221239 ELSE 1.1073857212572329 END )) AS pd_pit
  FROM rho_xdty r ),
u AS (
  SELECT 'V1_solo_clean'  AS version, flg_clean, personeria, target_12m, pd_pit FROM pit_cln
  UNION ALL SELECT 'V1_solo_clean',   flg_clean, personeria, target_12m, pd_pit FROM pit_xdty
  UNION ALL SELECT 'V2_clean_dirty',  flg_clean, personeria, target_12m, pd_pit FROM pit_cln
  UNION ALL SELECT 'V2_clean_dirty',  flg_clean, personeria, target_12m, pd_pit FROM pit_dty
),
g AS (
  SELECT version, personeria,
         CASE WHEN flg_clean=1 THEN 'CLEAN' ELSE 'DIRTY' END AS bloque,
         target_12m, pd_pit FROM u
)

SELECT version, bloque, personeria,
  count(*)                                        AS n,
  sum(target_12m)                                 AS defaults,
  round(100*avg(cast(target_12m AS double)), 2)   AS rd_obs_pct,
  round(100*avg(pd_pit), 2)                       AS pd_prom_pct,
  round(100*(avg(pd_pit)/nullif(avg(cast(target_12m AS double)),0) - 1), 1) AS ec_pct,
  round(100*inverse_beta_cdf(sum(target_12m)+0.5, count(*)-sum(target_12m)+0.5, 0.025), 2) AS jeff_lo,
  round(100*inverse_beta_cdf(sum(target_12m)+0.5, count(*)-sum(target_12m)+0.5, 0.975), 2) AS jeff_hi,
  CASE WHEN avg(pd_pit) BETWEEN
         inverse_beta_cdf(sum(target_12m)+0.5, count(*)-sum(target_12m)+0.5, 0.025)
     AND inverse_beta_cdf(sum(target_12m)+0.5, count(*)-sum(target_12m)+0.5, 0.975)
       THEN 'dentro' ELSE 'FUERA' END              AS banda,
  CASE WHEN avg(pd_pit) < avg(cast(target_12m AS double))
       THEN '*** SUB-PREDICE ***' ELSE 'conservador' END AS veredicto
FROM g GROUP BY version, bloque, personeria

UNION ALL
SELECT version, 'ZZ_TOTAL', personeria,
  count(*), sum(target_12m),
  round(100*avg(cast(target_12m AS double)), 2),
  round(100*avg(pd_pit), 2),
  round(100*(avg(pd_pit)/nullif(avg(cast(target_12m AS double)),0) - 1), 1),
  round(100*inverse_beta_cdf(sum(target_12m)+0.5, count(*)-sum(target_12m)+0.5, 0.025), 2),
  round(100*inverse_beta_cdf(sum(target_12m)+0.5, count(*)-sum(target_12m)+0.5, 0.975), 2),
  CASE WHEN avg(pd_pit) BETWEEN
         inverse_beta_cdf(sum(target_12m)+0.5, count(*)-sum(target_12m)+0.5, 0.025)
     AND inverse_beta_cdf(sum(target_12m)+0.5, count(*)-sum(target_12m)+0.5, 0.975)
       THEN 'dentro' ELSE 'FUERA' END,
  CASE WHEN avg(pd_pit) < avg(cast(target_12m AS double))
       THEN '*** SUB-PREDICE ***' ELSE 'conservador' END
FROM g GROUP BY version, personeria

UNION ALL
SELECT version, 'ZZZ_GLOBAL', 'ambas',
  count(*), sum(target_12m),
  round(100*avg(cast(target_12m AS double)), 2),
  round(100*avg(pd_pit), 2),
  round(100*(avg(pd_pit)/nullif(avg(cast(target_12m AS double)),0) - 1), 1),
  round(100*inverse_beta_cdf(sum(target_12m)+0.5, count(*)-sum(target_12m)+0.5, 0.025), 2),
  round(100*inverse_beta_cdf(sum(target_12m)+0.5, count(*)-sum(target_12m)+0.5, 0.975), 2),
  CASE WHEN avg(pd_pit) BETWEEN
         inverse_beta_cdf(sum(target_12m)+0.5, count(*)-sum(target_12m)+0.5, 0.025)
     AND inverse_beta_cdf(sum(target_12m)+0.5, count(*)-sum(target_12m)+0.5, 0.975)
       THEN 'dentro' ELSE 'FUERA' END,
  CASE WHEN avg(pd_pit) < avg(cast(target_12m AS double))
       THEN '*** SUB-PREDICE ***' ELSE 'conservador' END
FROM g GROUP BY version
ORDER BY version, bloque, personeria
