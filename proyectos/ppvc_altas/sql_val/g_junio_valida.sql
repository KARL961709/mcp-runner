-- =====================================================================================
-- g_junio_valida | Sanity 202606 P.FACIL. READ-ONLY.
--   (1) confirma subproducto (esperado '5.P FACIL' / '4.CD')
--   (2) valida que mi cadena reproduce la PIT oficial de la tabla: recomputo pd_pit_calc
--       con z_pf + rho + Vasicek (lambda 0.7107, f_t 0.11224983229263479) y lo comparo
--       contra prob_modelo_cal_ppfacil. Si mae ~0, la TTC derivada es confiable.
-- =====================================================================================
WITH base AS (
  SELECT subproducto,
         greatest(1e-9, least(1.0-1e-9, prob_modelo)) AS p,
         prob_modelo_cal_ppfacil AS pd_pit_tabla,
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
r AS (
  SELECT z.*, normal_cdf(0.0,1.0, z_pf) AS adj_pf,
    greatest(0.001, least(0.999,
      0.0498*(0.03*(1.0-exp(-35.0*normal_cdf(0.0,1.0,z_pf)))/(1.0-exp(-35.0))
            + 0.16*(1.0-(1.0-exp(-35.0*normal_cdf(0.0,1.0,z_pf)))/(1.0-exp(-35.0))))
      / 0.03296559147176952)) AS rho_pf
  FROM z
),
fin AS (
  SELECT r.*, normal_cdf(0.0,1.0, (z_pf - sqrt(rho_pf)*0.7107*0.11224983229263479)/sqrt(1.0-rho_pf)) AS pd_pit_calc
  FROM r
)
SELECT count(*) AS n,
       round(100*avg(p),2)            AS pdraw,
       round(100*avg(adj_pf),2)       AS pdttc,
       round(100*avg(pd_pit_tabla),2) AS pit_tabla,
       round(100*avg(pd_pit_calc),2)  AS pit_calc,
       round(100*avg(abs(pd_pit_tabla-pd_pit_calc)),3) AS mae_pit
FROM fin
