-- =====================================================================================
-- f_grupos_junjul | ENTREGABLE 202606 + 202607 -- Altas IBK P.FACIL: como cambia todo.
--   Por MES x GRUPO: N% + PDRAW + PDTTC + PDPIT, bajo los 3 sets de cortes. READ-ONLY.
--
-- Cruce (tu punto): la calibrada es el UNIVERSO -> altas salen de la fuente madre.
--   altas  = disc_model_owner.pp_vc_desembolsos  (codempresa 00002 = IBK, subproducto P.FACIL)
--   scores = d_perm_aws.scr_vcadmbnk_hist_rsk_cal_2606_2608  (universo calibrado)
--   join por key_value + codmes (mismo mes).
-- PD:
--   pd_raw = probabilidad (tabla)
--   pd_pit = prob_modelo_cal_ppfacil (tabla; PIT oficial, f_t del mes ya aplicado)
--   pd_ttc = normal_cdf(z_pf) = calibrada macro-neutral (derivada con cadena v7).
-- Cortes (score=1000*(1-PD)):
--   RAW [968,931,882,829,759] | TTC [962,935,893,855,789] | PIT [986,966,917,885,855]
-- =====================================================================================
WITH altas AS (
  SELECT DISTINCT cast(codmes AS varchar) AS codmes, key_value
  FROM disc_model_owner.pp_vc_desembolsos
  WHERE codempresa = '00002'
    AND cast(codmes AS varchar) IN ('202606', '202607')
    AND upper(subproducto) LIKE '%FACIL%'
),
base AS (
  SELECT a.codmes,
         greatest(1e-9, least(1.0-1e-9, c.probabilidad)) AS p,
         c.prob_modelo_cal_ppfacil AS pd_pit,
         c.trf_tipo_ingreso AS ti, c.trf_flg_meses AS fm, c.trf_flg_tc AS ftc,
         c.trf_rng_max_clasif AS rc, c.trf_flag_cuenta_sueldo AS cs, c.trf_flag_pasivos AS fp
  FROM altas a
  JOIN d_perm_aws.scr_vcadmbnk_hist_rsk_cal_2606_2608 c
    ON c.key_value = a.key_value
   AND cast(c.codmes AS varchar) = a.codmes
  WHERE cast(c.codmes AS varchar) IN ('202606', '202607')
),
z AS (
  SELECT b.*,
    ( inverse_normal_cdf(0.0,1.0, greatest(1e-9, least(1.0-1e-9,
        CASE WHEN ti='DEP'
             THEN 1.0/(1.0+exp(-(0.4949441034126291 + 1.3561989275278388*ln(p) - (-0.42742603206965946)*ln(1.0-p))))
             ELSE 1.0/(1.0+exp(-(0.437337856467009  + 1.137793241117395*ln(p) - (-0.25573721776913255)*ln(1.0-p)))) END)))
      + (CASE WHEN ti='DEP'      THEN 0.07967553360569396  ELSE 0.0 END)
      + (-0.038408753726545064)
      + (CASE WHEN fm='menor 36' THEN 0.15869973303724544  ELSE 0.0 END)
      + (CASE WHEN cs='1'        THEN -0.12342472622838346 ELSE 0.0 END)
      + (CASE WHEN rc='NORMAL'   THEN 0.07580726588531653  ELSE 0.0 END)
      + (CASE WHEN fp='1'        THEN -0.08816302066822071 ELSE 0.0 END)
      + (CASE WHEN ftc='1'       THEN -0.0010394697061275912 ELSE 0.0 END)
    ) AS z_pf
  FROM base b
),
sc AS (
  SELECT codmes, p AS pd_raw, normal_cdf(0.0,1.0, z_pf) AS pd_ttc, pd_pit,
         1000.0*(1.0-p)                        AS s_raw,
         1000.0*(1.0-normal_cdf(0.0,1.0,z_pf)) AS s_ttc,
         1000.0*(1.0-pd_pit)                   AS s_pit
  FROM z
),
g AS (
  SELECT sc.*,
    CASE WHEN s_raw>=968 THEN 'G1' WHEN s_raw>=931 THEN 'G2' WHEN s_raw>=882 THEN 'G3' WHEN s_raw>=829 THEN 'G4' WHEN s_raw>=759 THEN 'G5' ELSE 'GR' END AS g_raw,
    CASE WHEN s_ttc>=962 THEN 'G1' WHEN s_ttc>=935 THEN 'G2' WHEN s_ttc>=893 THEN 'G3' WHEN s_ttc>=855 THEN 'G4' WHEN s_ttc>=789 THEN 'G5' ELSE 'GR' END AS g_ttc,
    CASE WHEN s_pit>=986 THEN 'G1' WHEN s_pit>=966 THEN 'G2' WHEN s_pit>=917 THEN 'G3' WHEN s_pit>=885 THEN 'G4' WHEN s_pit>=855 THEN 'G5' ELSE 'GR' END AS g_pit
  FROM sc
)
SELECT codmes, 'V1_cortes_RAW' AS version, g_raw AS grupo, count(*) AS n,
       round(100.0*count(*)/sum(count(*)) over (partition by codmes),1) AS pct_n,
       round(100*avg(pd_raw),2) AS pdraw, round(100*avg(pd_ttc),2) AS pdttc, round(100*avg(pd_pit),2) AS pdpit
FROM g GROUP BY codmes, g_raw
UNION ALL
SELECT codmes, 'V2_cortes_TTC', g_ttc, count(*),
       round(100.0*count(*)/sum(count(*)) over (partition by codmes),1),
       round(100*avg(pd_raw),2), round(100*avg(pd_ttc),2), round(100*avg(pd_pit),2)
FROM g GROUP BY codmes, g_ttc
UNION ALL
SELECT codmes, 'V3_cortes_PIT', g_pit, count(*),
       round(100.0*count(*)/sum(count(*)) over (partition by codmes),1),
       round(100*avg(pd_raw),2), round(100*avg(pd_ttc),2), round(100*avg(pd_pit),2)
FROM g GROUP BY codmes, g_pit
ORDER BY version, codmes, grupo
