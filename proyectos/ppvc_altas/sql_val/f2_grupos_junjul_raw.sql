-- =====================================================================================
-- f2_grupos_junjul_raw | ENTREGABLE jun+jul desde la MADRE RAW (pp_vc_desembolsos stale).
--   Variacion de N% por grupo bajo PD RAW / TTC / PIT con sus cortes optimizados. READ-ONLY.
--
--   Altas IBK P.FACIL <- disc_monitorian.t_mrm_mongest_altas_pp_marcas  (monitoreo raw)
--        cif_key -> cod_cuc (lpad 10) -> key_value via e_perm_aws.t_mst_ctaibk_rsk   (logica 01_desembolsos)
--   Scores  <- d_perm_aws.scr_vcadmbnk_hist_rsk_cal_2606_2608  (universo calibrado)
--        join key_value + codmes
--   pd_raw=probabilidad | pd_pit=prob_modelo_cal_ppfacil | pd_ttc=normal_cdf(z_pf) (cadena v7)
--   Cortes: RAW [968,931,882,829,759] TTC [962,935,893,855,789] PIT [986,966,917,885,855]
-- =====================================================================================
WITH mon AS (
  -- altas NUEVAS puras: P.FACIL, sin swap (reemplazo de deuda) ni CIMA
  SELECT cast(codmes_desembolso AS varchar) AS codmes,
         CASE WHEN length(cif_key) >= 10 THEN cif_key ELSE lpad(cif_key, 10, '0') END AS cod_cuc
  FROM disc_monitorian.t_mrm_mongest_altas_pp_marcas
  WHERE cast(codmes_desembolso AS varchar) IN ('202606', '202607')
    AND upper(subproducto) LIKE '%FACIL%'
    AND coalesce(cast(flg_swap AS varchar), '0') <> '1'
    AND coalesce(cast(flg_cima AS varchar), '0') <> '1'
),
altas AS (
  SELECT DISTINCT m.codmes, b.key_value
  FROM mon m
  JOIN e_perm_aws.t_mst_ctaibk_rsk b ON b.cod_cuc = m.cod_cuc
  WHERE b.key_value IS NOT NULL
),
base AS (
  SELECT a.codmes,
         greatest(1e-9, least(1.0-1e-9, c.probabilidad)) AS p,
         c.prob_modelo_cal_ppfacil AS pd_pit,
         c.trf_tipo_ingreso AS ti, c.trf_flg_meses AS fm, c.trf_flg_tc AS ftc,
         c.trf_rng_max_clasif AS rc, c.trf_flag_cuenta_sueldo AS cs, c.trf_flag_pasivos AS fp
  FROM altas a
  JOIN d_perm_aws.scr_vcadmbnk_hist_rsk_cal_2606_2608 c
    ON c.key_value = a.key_value AND cast(c.codmes AS varchar) = a.codmes
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
