-- =====================================================================================
-- ORIGEN BPE PD · V2 · VALIDACION (read-only)
--   archivo : C_calibra/C2_ec_mensual.sql
--   origen  : ~\mcp-runner\sql\C2_ec_mensual.sql
--   sha256  : 8c86507b45a4   (del cuerpo, sin este encabezado)
--   estado  : VERDE
--   nota    : EC mes a mes
-- =====================================================================================
-- =====================================================================================
-- C2 | CALIBRACION — EC mes a mes
-- El agregado puede estar en cero y esconder meses descalibrados que se compensan.
-- Esto lo abre por cohorte. El f_t es lo que debe absorber el ciclo.
--
-- CRITERIO DE APROBACION
--   * n_sub (meses que sub-predicen) bajo y sin racha larga
--   * dentro_banda = 'si' en la gran mayoria de meses
--   * si un mes se sale mucho, mirar si es un mes con pocos casos (n chico)
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
  SELECT cast(tip_doc AS varchar) AS tip_doc, key_value,
         cast(p_codmes AS int) AS p_codmes, max(probabilidad) AS pd_raw
  FROM e_perm_aws.scr_admbankbpe_rsk
  WHERE p_codmes BETWEEN '202206' AND '202504'
  GROUP BY 1,2,3
),
base AS (
  SELECT cast(a.codmes AS int) AS codmes,
         CASE WHEN a.tip_doc='2' THEN 'PJJ' ELSE 'PNN' END AS personeria,
         a.flg_calib_m2 AS flg_clean,
         a.target_12m,
         greatest(1e-6, least(1-1e-6, p.pd_raw)) AS pd_raw,
         f.fhat
  FROM disc_model_owner.bnbpe_ibk_calib_src a
  JOIN pdr p ON p.tip_doc=cast(a.tip_doc AS varchar) AND p.key_value=a.key_value
            AND p.p_codmes = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m')
                                              - interval '1' month,'%Y%m') AS int)
  JOIN ft f ON f.codmes_alta = cast(a.codmes AS int)
  WHERE a.flg_ibk=1
    AND a.top4_entidad='TOP4'
    AND cast(a.codmes AS int) BETWEEN 202207 AND 202505   -- 12m de maduracion cerrada
    AND cast(a.codmes AS int) NOT BETWEEN 202310 AND 202412                                            -- ex era Impulsa
),
cln AS (SELECT * FROM base WHERE flg_clean=1),
dty AS (SELECT * FROM base WHERE flg_clean=0),
niv_cln AS (
  SELECT b.*, greatest(1e-6, least(1-1e-6,
    CASE WHEN b.personeria='PNN'
      THEN 1.0/(1.0+exp(-( -0.72488396139167532 + 0.63943961553578943*ln(b.pd_raw) + -1.0325848544388896*ln(1.0-b.pd_raw) )))
      ELSE 1.0/(1.0+exp(-( 0.17759688908412222 + 1.058477056441401*(ln(b.pd_raw)-ln(1.0-b.pd_raw)) ))) END )) AS pd_cal
  FROM cln b
),
rho_cln AS (
  SELECT n.*, greatest(0.001, least(0.999,
    0.035978817268325414 * ( 0.03*((1-exp(-35*n.pd_cal))/(1-exp(-35.0)))
            + 0.16*(1-(1-exp(-35*n.pd_cal))/(1-exp(-35.0))) )
    / CASE WHEN n.personeria='PNN' THEN 0.035560752391369591 ELSE 0.03634808815365035 END )) AS rho_i
  FROM niv_cln n
),
pit_cln AS (
  SELECT r.*, greatest(1e-6, least(1.0,
    greatest(1e-6, least(1-1e-6,
      normal_cdf(0,1,(inverse_normal_cdf(0,1,r.pd_cal) - sqrt(r.rho_i)*0.34999999999999998*r.fhat)
                     / sqrt(1.0-r.rho_i))
      * CASE WHEN r.personeria='PNN' THEN 1.1306030131221239 ELSE 1.1073857212572329 END ))
    * (1.0 + 0.15148849492598418) )) AS pd_final
  FROM rho_cln r
),
niv_dty AS (
  SELECT b.*, greatest(1e-6, least(1-1e-6,
    CASE WHEN b.personeria='PNN'
      THEN 1.0/(1.0+exp(-( -0.15676765088130001 + 0.64162444955106612*ln(b.pd_raw) + 0.083173096581749414*ln(1.0-b.pd_raw) )))
      ELSE 1.0/(1.0+exp(-( -0.60971743608471285 + 0.85566792258078261*(ln(b.pd_raw)-ln(1.0-b.pd_raw)) ))) END )) AS pd_cal
  FROM dty b
),
rho_dty AS (
  SELECT n.*, greatest(0.001, least(0.999,
    0.035978817268325414 * ( 0.03*((1-exp(-35*n.pd_cal))/(1-exp(-35.0)))
            + 0.16*(1-(1-exp(-35*n.pd_cal))/(1-exp(-35.0))) )
    / CASE WHEN n.personeria='PNN' THEN 0.030343535251014398 ELSE 0.036801943015635719 END )) AS rho_i
  FROM niv_dty n
),
pit_dty AS (
  SELECT r.*, greatest(1e-6, least(1.0,
    greatest(1e-6, least(1-1e-6,
      normal_cdf(0,1,(inverse_normal_cdf(0,1,r.pd_cal) - sqrt(r.rho_i)*0.34999999999999998*r.fhat)
                     / sqrt(1.0-r.rho_i))
      * CASE WHEN r.personeria='PNN' THEN 1.0801021982671937 ELSE 1.1207211368581367 END ))
    * (1.0 + 0.19466271597988966) )) AS pd_final
  FROM rho_dty r
),
todo AS (
  SELECT codmes, personeria, flg_clean, target_12m, pd_raw, pd_final FROM pit_cln
  UNION ALL
  SELECT codmes, personeria, flg_clean, target_12m, pd_raw, pd_final FROM pit_dty
)

SELECT codmes,
  CASE WHEN flg_clean=1 THEN 'CLEAN' ELSE 'DIRTY' END AS bloque,
  count(*)                        AS n,
  sum(target_12m)                 AS defaults,
  avg(cast(target_12m AS double)) AS rd_obs,
  avg(pd_final)                   AS pd_prom,
  avg(pd_final)/nullif(avg(cast(target_12m AS double)),0) - 1 AS ec,
  CASE WHEN avg(pd_final) BETWEEN
         inverse_beta_cdf(sum(target_12m)+0.5, count(*)-sum(target_12m)+0.5, 0.025)
     AND inverse_beta_cdf(sum(target_12m)+0.5, count(*)-sum(target_12m)+0.5, 0.975)
       THEN 'si' ELSE 'NO' END AS dentro_banda,
  CASE WHEN avg(pd_final) < avg(cast(target_12m AS double)) THEN 'SUB' ELSE '' END AS sub
FROM todo
GROUP BY 1,2
ORDER BY 1,2
