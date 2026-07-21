-- =====================================================================================
-- G2 | GRUPOS sobre el TOTAL de altas — puntuacion vs PD vs RD observada
--
-- Los cortes NO se optimizan: son los niveles de PD del APETITO BN traducidos a
-- puntuacion (28_grupos_admision.py L44):
--     apetito G1..G5 = 2.43% / 4.60% / 6.75% / 10.08% / 32.03%
--     CUTS = round((1 - PD_apetito) * 1000) = [976, 954, 933, 900]
-- Van sobre pd_pit (SIN MoC), que es lo que alimenta `puntuacion`.
--
-- POBLACION: TODAS las altas IBK con 12m cerrados (202207-202505), ex era Impulsa,
-- clean Y dirty juntos, cada uno con SU cadena. Un unico juego de cortes para ambos:
-- la premisa es equi-riesgo (a igual PD, igual RD entre bloques). Este query la PRUEBA.
--
-- CRITERIO DE APROBACION
--   * rd_obs MONOTONA creciente de G1 a G5. Un quiebre rompe el orden del apetito.
--   * gap_pp = rd_obs - apetito, acotado. Si un grupo se dispara, el corte no entrega
--     el riesgo que promete y hay que revisar apetito o calibracion.
--   * pd_pit_prom ~ rd_obs dentro de cada grupo (es la calibracion, vista por grupo).
--   * pct_n razonable; ningun grupo degenerado.
-- READ-ONLY.
-- =====================================================================================

WITH ft (codmes_alta, fhat, meses_usados) AS ( VALUES
  (202207, 0.46731627731126968, 3),
  (202208, 0.056728699947162099, 3),
  (202209, -0.38935742968535247, 3),
  (202210, -0.70072994178821002, 3),
  (202211, -0.85205451520464348, 3),
  (202212, -0.92891552347195483, 3),
  (202301, -1.0159184358416815, 3),
  (202302, -1.0379535945181364, 3),
  (202303, -1.0609231368183629, 3),
  (202304, -1.105625425606386, 3),
  (202305, -1.1568688592667788, 3),
  (202306, -1.1568688592667788, 3),
  (202307, -0.94596279749778256, 3),
  (202308, -0.51623687799565809, 3),
  (202309, -0.030103544427882899, 3),
  (202310, 0.32449026737520231, 3),
  (202311, 0.52946365930378281, 3),
  (202312, 0.68472846461918047, 3),
  (202401, 0.88376877419346278, 3),
  (202402, 1.0779696991599816, 3),
  (202403, 1.2044927251923596, 3),
  (202404, 1.201179762312532, 3),
  (202405, 1.1457097080976519, 3),
  (202406, 1.104751202610557, 3),
  (202407, 1.1060161144381395, 3),
  (202408, 1.1019902137713098, 3),
  (202409, 1.1002452201190325, 3),
  (202410, 1.1875559465718, 3),
  (202411, 1.3180022720336295, 3),
  (202412, 1.4595914586518206, 3),
  (202501, 1.5193331146887308, 3),
  (202502, 1.5295598659038827, 3),
  (202503, 1.5467370500137263, 3),
  (202504, 1.6703824334712063, 3),
  (202505, 1.8720398724011265, 3),
  (202506, 2.0194314436566057, 3),
  (202507, 2.0194314436566057, 3),
  (202508, 2.0194314436566057, 3),
  (202509, 2.0194314436566057, 3),
  (202510, 2.0194314436566057, 3),
  (202511, 2.0194314436566057, 3),
  (202512, 2.0194314436566057, 3),
  (202601, 2.0194314436566057, 3),
  (202602, 2.0194314436566057, 3),
  (202603, 2.0194314436566057, 3),
  (202604, 1.9724204666385832, 3),
  (202605, 1.4715585841909371, 3),
  (202606, 0.8175440736248093, 3),
  (202607, 0.2008886726564256, 3),
  (202608, -0.021384045860002102, 3),
  (202609, -0.034594450720994298, 2)
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
    AND cast(a.codmes AS int) NOT BETWEEN 202310 AND 202412
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
todo AS (
  SELECT flg_clean, target_12m, pd_pit FROM pit_cln
  UNION ALL SELECT flg_clean, target_12m, pd_pit FROM pit_dty
),
gr AS (
  SELECT t.*, cast(round((1.0 - pd_pit)*1000) AS integer) AS puntuacion,
    CASE WHEN round((1.0-pd_pit)*1000) >= 976 THEN 'G1'
         WHEN round((1.0-pd_pit)*1000) >= 954 THEN 'G2'
         WHEN round((1.0-pd_pit)*1000) >= 933 THEN 'G3'
         WHEN round((1.0-pd_pit)*1000) >= 900 THEN 'G4'
         ELSE 'G5' END AS grupo
  FROM todo t
),
ape (grupo, apetito) AS ( VALUES ('G1',0.0243),('G2',0.0460),('G3',0.0675),('G4',0.1008),('G5',0.3203) )

SELECT g.grupo,
  count(*)                                        AS n,
  round(100.0*count(*)/sum(count(*)) OVER (), 1)  AS pct_n,
  min(g.puntuacion)                               AS punt_min,
  max(g.puntuacion)                               AS punt_max,
  sum(g.target_12m)                               AS defaults,
  round(100*avg(g.pd_pit), 2)                     AS pd_pit_prom_pct,
  round(100*avg(cast(g.target_12m AS double)), 2) AS rd_obs_pct,
  round(100*max(a.apetito), 2)                    AS apetito_pct,
  round(100*(avg(cast(g.target_12m AS double)) - max(a.apetito)), 2) AS gap_pp,
  count_if(g.flg_clean=1)                         AS de_clean,
  count_if(g.flg_clean=0)                         AS de_dirty
FROM gr g JOIN ape a ON a.grupo = g.grupo
GROUP BY g.grupo
ORDER BY g.grupo
