-- =====================================================================================
-- g_junio_grupos | ENTREGABLE 202606 -- Altas P.FACIL: N% + PDRAW/PDTTC/PDPIT por grupo,
--   bajo los 3 sets de cortes optimizados (RAW / TTC / PIT). READ-ONLY.
--
-- Fuente: d_perm_aws.scr_vcadmbnk_cal_202606 (altas calibradas, trae subproducto).
--   pd_raw = prob_modelo (tabla)
--   pd_pit = prob_modelo_cal_ppfacil (tabla, PIT oficial de produccion)
--   pd_ttc = adj_pf = normal_cdf(z_pf)  -> derivada aqui con la cadena v7 (BetaCal +
--            shifts de drivers), lo UNICO que la tabla no expone.
-- Cortes (score=1000*(1-PD)):
--   RAW [968,931,882,829,759] | TTC [962,935,893,855,789] | PIT [986,966,917,885,855]
-- =====================================================================================
WITH base AS (
  SELECT greatest(1e-9, least(1.0-1e-9, prob_modelo)) AS p,
         prob_modelo_cal_ppfacil AS pd_pit,
         trf_tipo_ingreso AS ti, trf_flg_meses AS fm, trf_flg_tc AS ftc,
         trf_rng_max_clasif AS rc, trf_flag_cuenta_sueldo AS cs, trf_flag_pasivos AS fp
  FROM d_perm_aws.scr_vcadmbnk_cal_202606
  WHERE subproducto = '5.P FACIL'
),
z AS (
  SELECT b.*,
    ( inverse_normal_cdf(0.0,1.0, greatest(1e-9, least(1.0-1e-9,
        CASE WHEN ti='DEP'
             THEN 1.0/(1.0+exp(-(0.4949441034126291 + 1.3561989275278388*ln(p) - (-0.42742603206965946)*ln(1.0-p))))
             ELSE 1.0/(1.0+exp(-(0.437337856467009  + 1.137793241117395*ln(p) - (-0.25573721776913255)*ln(1.0-p)))) END)))
      + (CASE WHEN ti='DEP'        THEN 0.07967553360569396  ELSE 0.0 END)
      + (-0.038408753726545064)
      + (CASE WHEN fm='menor 36'   THEN 0.15869973303724544  ELSE 0.0 END)
      + (CASE WHEN cs='1'          THEN -0.12342472622838346 ELSE 0.0 END)
      + (CASE WHEN rc='NORMAL'     THEN 0.07580726588531653  ELSE 0.0 END)
      + (CASE WHEN fp='1'          THEN -0.08816302066822071 ELSE 0.0 END)
      + (CASE WHEN ftc='1'         THEN -0.0010394697061275912 ELSE 0.0 END)
    ) AS z_pf
  FROM base b
),
pd AS (
  SELECT z.*, p AS pd_raw, normal_cdf(0.0,1.0, z_pf) AS pd_ttc FROM z
),
sc AS (
  SELECT pd_raw, pd_ttc, pd_pit,
         1000.0*(1.0-pd_raw) AS s_raw,
         1000.0*(1.0-pd_ttc) AS s_ttc,
         1000.0*(1.0-pd_pit) AS s_pit
  FROM pd
),
g AS (
  SELECT sc.*,
    CASE WHEN s_raw>=968 THEN 'G1' WHEN s_raw>=931 THEN 'G2' WHEN s_raw>=882 THEN 'G3' WHEN s_raw>=829 THEN 'G4' WHEN s_raw>=759 THEN 'G5' ELSE 'GR' END AS g_raw,
    CASE WHEN s_ttc>=962 THEN 'G1' WHEN s_ttc>=935 THEN 'G2' WHEN s_ttc>=893 THEN 'G3' WHEN s_ttc>=855 THEN 'G4' WHEN s_ttc>=789 THEN 'G5' ELSE 'GR' END AS g_ttc,
    CASE WHEN s_pit>=986 THEN 'G1' WHEN s_pit>=966 THEN 'G2' WHEN s_pit>=917 THEN 'G3' WHEN s_pit>=885 THEN 'G4' WHEN s_pit>=855 THEN 'G5' ELSE 'GR' END AS g_pit
  FROM sc
)
SELECT 'V1_cortes_RAW' AS version, g_raw AS grupo, count(*) AS n,
       round(100.0*count(*)/sum(count(*)) over (),1) AS pct_n,
       round(100*avg(pd_raw),2) AS pdraw, round(100*avg(pd_ttc),2) AS pdttc, round(100*avg(pd_pit),2) AS pdpit
FROM g GROUP BY g_raw
UNION ALL
SELECT 'V2_cortes_TTC', g_ttc, count(*),
       round(100.0*count(*)/sum(count(*)) over (),1),
       round(100*avg(pd_raw),2), round(100*avg(pd_ttc),2), round(100*avg(pd_pit),2)
FROM g GROUP BY g_ttc
UNION ALL
SELECT 'V3_cortes_PIT', g_pit, count(*),
       round(100.0*count(*)/sum(count(*)) over (),1),
       round(100*avg(pd_raw),2), round(100*avg(pd_ttc),2), round(100*avg(pd_pit),2)
FROM g GROUP BY g_pit
ORDER BY version, grupo
