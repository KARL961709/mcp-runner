-- =====================================================================================
-- G1 | QA del scoring de la PO — UN MES (p_codmes = 202606)
--
-- Misma cadena que SCORING_PO.sql, pero devuelve ~3 filas de diagnostico en vez de ~4M.
-- Sirve para validar ANTES de materializar.
--
-- CRITERIO DE APROBACION
--   nulos_cal = nulos_fin = nulos_punt = 0      toda fila debe recibir PD
--   ft_min_meses = 3                            f_t firme, ningun provisional
--   pdraw_max_pct < 100                         si llega a 100 hay pd_raw = 1 exacto
--   pdraw_topados                               cuantos toca el clamp [1e-6, 1-1e-6];
--                                               si es alto, revisar la fuente
--   pd_cal_prom_pct                             debe ser plausible vs la LRA clean (~9%)
--   g1..g5                                      la distribucion no debe concentrarse en un grupo
--
-- OJO: prob_modelo_cal usa la cadena CLEAN (precedente q7). Ver ADVERTENCIA 2 del SQL madre.
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

-- PO completa: ~4M filas/mes. dedup max(probabilidad) — misma regla que q3/q6/q7.
b AS (
  SELECT cast(tip_doc AS varchar) AS tip_doc, key_value,
         cast(p_codmes AS int) AS p_codmes,
         max(probabilidad) AS pd_raw
  FROM e_perm_aws.scr_admbankbpe_rsk
  WHERE p_codmes BETWEEN '202606' AND '202606'
  GROUP BY 1,2,3
),

-- bloque RCC @ codmes_alta - 2 = p_codmes - 1.  SOLO INDICATIVO (ver ADVERTENCIA 2).
rcc AS (
  SELECT cast(tip_doc AS varchar) AS tip_doc, key_value, cast(codmes AS int) AS codmes,
    max(CASE WHEN cast(tipo_credito AS int) BETWEEN 1 AND 10
             AND ( (substr(cod_cuenta_rcc,1,2) = '14'
                    AND substr(cod_cuenta_rcc,7,2) NOT IN ('01','04')
                    AND substr(cod_cuenta_rcc,4,1) IN ('1','3','4','5','6'))
                OR (substr(cod_cuenta_rcc,1,2) = '81'
                    AND substr(cod_cuenta_rcc,4,3) IN ('302','925')) )
            THEN cast(condicion AS double) END) AS dm,
    max(CASE WHEN substr(cod_cuenta_rcc,1,2)='14' AND substr(cod_cuenta_rcc,4,1)='6'
             THEN 1 ELSE 0 END) AS f_jud,
    max(CASE WHEN substr(cod_cuenta_rcc,1,2)='81' AND substr(cod_cuenta_rcc,4,3) IN ('302','925')
             THEN 1 ELSE 0 END) AS f_cast,
    max(CASE WHEN substr(cod_cuenta_rcc,1,2)='14' AND substr(cod_cuenta_rcc,4,1)='4'
             THEN 1 ELSE 0 END) AS f_ref,
    max(CASE WHEN substr(cod_cuenta_rcc,1,2)='14' AND substr(cod_cuenta_rcc,4,1)='3'
             THEN 1 ELSE 0 END) AS f_ree,
    max(CASE WHEN cod_clasificacion_deudor IS NOT NULL
              AND cast(cod_clasificacion_deudor AS int) > 0 THEN 1 ELSE 0 END) AS f_clasif
  FROM e_perm_aws.t_fact_report_rcc_rsk
  WHERE cod_instit_financiera = '00002'
    AND p_codmes BETWEEN cast(date_format(date_parse('202606','%Y%m')
                                          - interval '1' month,'%Y%m') AS varchar)
                     AND cast(date_format(date_parse('202606','%Y%m')
                                          - interval '1' month,'%Y%m') AS varchar)
  GROUP BY 1,2,3
),

base AS (
  SELECT
    b.p_codmes,
    cast(date_format(date_parse(cast(b.p_codmes AS varchar),'%Y%m')
                     + interval '1' month,'%Y%m') AS int) AS codmes_alta,
    b.tip_doc, b.key_value,
    CASE WHEN b.tip_doc = '2' THEN 'PJJ' ELSE 'PNN' END AS personeria,
    greatest(1e-6, least(1-1e-6, b.pd_raw)) AS pd_raw,
    f.fhat, f.meses_usados AS ft_meses_usados,
    CASE WHEN coalesce(r.dm,0) > 90
           OR coalesce(r.f_jud,0)   = 1 OR coalesce(r.f_cast,0) = 1
           OR coalesce(r.f_ref,0)   = 1 OR coalesce(r.f_ree,0)  = 1
           OR coalesce(r.f_clasif,0)= 1
         THEN 0 ELSE 1 END AS flg_clean_rcc
  FROM b
  JOIN ft f
    ON f.codmes_alta = cast(date_format(date_parse(cast(b.p_codmes AS varchar),'%Y%m')
                                        + interval '1' month,'%Y%m') AS int)
  LEFT JOIN rcc r
    ON r.tip_doc = b.tip_doc AND r.key_value = b.key_value
   AND r.codmes  = cast(date_format(date_parse(cast(b.p_codmes AS varchar),'%Y%m')
                                    - interval '1' month,'%Y%m') AS int)
  WHERE b.pd_raw IS NOT NULL
),

niv_cln AS (
  SELECT b.*,
    greatest(1e-6, least(1-1e-6,
      CASE WHEN b.personeria = 'PNN'
        THEN 1.0/(1.0 + exp(-( -0.72488396139167532 + 0.63943961553578943*ln(b.pd_raw) + -1.0325848544388896*ln(1.0-b.pd_raw) )))
        ELSE 1.0/(1.0 + exp(-( 0.17759688908412222 + 1.058477056441401*(ln(b.pd_raw) - ln(1.0-b.pd_raw)) )))
      END )) AS pd_cal
  FROM base b
),
rho_cln AS (
  SELECT n.*,
    greatest(0.001, least(0.999,
      0.035978817268325414 * ( 0.03*((1 - exp(-35*n.pd_cal))/(1 - exp(-35.0)))
              + 0.16*(1 - (1 - exp(-35*n.pd_cal))/(1 - exp(-35.0))) )
      / CASE WHEN n.personeria = 'PNN' THEN 0.035560752391369591 ELSE 0.03634808815365035 END )) AS rho_i
  FROM niv_cln n
),
pit_cln AS (
  SELECT r.*,
    greatest(1e-6, least(1-1e-6,
      normal_cdf(0, 1, (inverse_normal_cdf(0, 1, r.pd_cal)
                        - sqrt(r.rho_i) * 0.34999999999999998 * r.fhat) / sqrt(1.0 - r.rho_i))
      * CASE WHEN r.personeria = 'PNN' THEN 1.1306030131221239 ELSE 1.1073857212572329 END )) AS pd_pit
  FROM rho_cln r
),

niv_dty AS (
  SELECT b.*,
    greatest(1e-6, least(1-1e-6,
      CASE WHEN b.personeria = 'PNN'
        THEN 1.0/(1.0 + exp(-( -0.15676765088130001 + 0.64162444955106612*ln(b.pd_raw) + 0.083173096581749414*ln(1.0-b.pd_raw) )))
        ELSE 1.0/(1.0 + exp(-( -0.60971743608471285 + 0.85566792258078261*(ln(b.pd_raw) - ln(1.0-b.pd_raw)) )))
      END )) AS pd_cal
  FROM base b
),
rho_dty AS (
  SELECT n.*,
    greatest(0.001, least(0.999,
      0.035978817268325414 * ( 0.03*((1 - exp(-35*n.pd_cal))/(1 - exp(-35.0)))
              + 0.16*(1 - (1 - exp(-35*n.pd_cal))/(1 - exp(-35.0))) )
      / CASE WHEN n.personeria = 'PNN' THEN 0.030343535251014398 ELSE 0.036801943015635719 END )) AS rho_i
  FROM niv_dty n
),
pit_dty AS (
  SELECT r.*,
    greatest(1e-6, least(1-1e-6,
      normal_cdf(0, 1, (inverse_normal_cdf(0, 1, r.pd_cal)
                        - sqrt(r.rho_i) * 0.34999999999999998 * r.fhat) / sqrt(1.0 - r.rho_i))
      * CASE WHEN r.personeria = 'PNN' THEN 1.0801021982671937 ELSE 1.1207211368581367 END )) AS pd_pit
  FROM rho_dty r
)

, res AS (
SELECT
  c.p_codmes, c.codmes_alta, c.tip_doc, c.key_value, c.personeria,
  c.pd_raw AS prob_modelo, c.fhat, c.ft_meses_usados, c.flg_clean_rcc,

  c.pd_pit AS prob_modelo_cal_clean,
  greatest(1e-6, least(1.0, c.pd_pit * (1.0 + 0.15148849492598418))) AS prob_modelo_fin_clean,
  cast(round((1.0 - c.pd_pit) * 1000) AS integer)       AS puntuacion_clean,

  d.pd_pit AS prob_modelo_cal_dirty,
  greatest(1e-6, least(1.0, d.pd_pit * (1.0 + 0.19466271597988966))) AS prob_modelo_fin_dirty,
  cast(round((1.0 - d.pd_pit) * 1000) AS integer)       AS puntuacion_dirty,

  -- cadena CLEAN por precedente q7 (ver ADVERTENCIA 2). Explicito, no implicito.
  c.pd_pit                                              AS prob_modelo_cal,
  greatest(1e-6, least(1.0, c.pd_pit * (1.0 + 0.15148849492598418))) AS prob_modelo_fin,
  cast(round((1.0 - c.pd_pit) * 1000) AS integer)       AS puntuacion_cal,
  CASE WHEN round((1.0-c.pd_pit)*1000) >= 976 THEN 'G1'
       WHEN round((1.0-c.pd_pit)*1000) >= 954 THEN 'G2'
       WHEN round((1.0-c.pd_pit)*1000) >= 933 THEN 'G3'
       WHEN round((1.0-c.pd_pit)*1000) >= 900 THEN 'G4'
       ELSE 'G5' END                                    AS grupos_cal
FROM pit_cln c
JOIN pit_dty d
  ON d.p_codmes = c.p_codmes AND d.tip_doc = c.tip_doc AND d.key_value = c.key_value
)

SELECT
  coalesce(personeria,'ZZ TOTAL')                              AS personeria,
  count(*)                                                     AS n,
  count_if(prob_modelo_cal IS NULL)                            AS nulos_cal,
  count_if(prob_modelo_fin IS NULL)                            AS nulos_fin,
  count_if(puntuacion_cal  IS NULL)                            AS nulos_punt,
  round(min(prob_modelo)*100, 4)                               AS pdraw_min_pct,
  round(max(prob_modelo)*100, 4)                               AS pdraw_max_pct,
  count_if(prob_modelo <= 1e-6 OR prob_modelo >= 1-1e-6)        AS pdraw_topados,
  round(avg(prob_modelo_cal)*100, 4)                           AS pd_cal_prom_pct,
  round(min(prob_modelo_cal)*100, 4)                           AS pd_cal_min_pct,
  round(max(prob_modelo_cal)*100, 4)                           AS pd_cal_max_pct,
  round(avg(prob_modelo_fin)*100, 4)                           AS pd_fin_prom_pct,
  count_if(flg_clean_rcc = 0)                                  AS rcc_adverso,
  min(ft_meses_usados)                                         AS ft_min_meses,
  count_if(grupos_cal='G1') AS g1, count_if(grupos_cal='G2') AS g2,
  count_if(grupos_cal='G3') AS g3, count_if(grupos_cal='G4') AS g4,
  count_if(grupos_cal='G5') AS g5
FROM res
GROUP BY GROUPING SETS ((personeria), ())
ORDER BY 1
