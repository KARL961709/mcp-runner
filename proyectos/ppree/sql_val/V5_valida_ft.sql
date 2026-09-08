-- ============================================================================
-- V5. VALIDA f_t del ds nuevo vs la vigente
--   Recalcula f_t con las MISMAS CTEs del inference.sql (cal_meses/ipc/mac/ft)
--   y lo compara contra trf_f_t guardado en d_perm_aws.scr_stk_ree_pp_cal_202607.
--   Gate: max_abs_dif ~ 0 (los meses que topan el cap pueden dar ~1e-10).
-- ============================================================================
WITH cal_meses AS (
  SELECT date_format(m, '%Y%m') AS cm
    FROM UNNEST(sequence(date '2018-01-01', date '2027-12-01', interval '1' month)) AS t(m)),
ipc AS (
  SELECT c.cm, max(cast(b.porc_ipc AS double)) AS ipc
    FROM cal_meses c
    LEFT JOIN e_perm_aws.t_mst_bcrp_rsk b ON cast(b.cod_mes AS varchar) = c.cm
   GROUP BY 1),
mac AS (
  SELECT cm,
         avg(ipc)   OVER (ORDER BY cm ROWS BETWEEN 10 PRECEDING AND 5 PRECEDING) AS x,
         count(ipc) OVER (ORDER BY cm ROWS BETWEEN 10 PRECEDING AND 5 PRECEDING) AS n_vent
    FROM ipc),
ft AS (
  SELECT cm AS codmes_mrm,
         greatest(least(
           (inverse_normal_cdf(0.0, 1.0, 0.04226346409008948)
             - sqrt(1.0 - 0.038030115964094044) * (-1.900195796163702 + 0.6583423568236846 * x))
           / sqrt(0.038030115964094044)
           + 0.19111262350586136
         , 0.7656842281878757), -1.1308495593693428) AS f_t
    FROM mac
   WHERE n_vent = 6)
SELECT count(*)                                AS n_meses,
       max(abs(v.trf_f_t - f.f_t))             AS max_abs_dif
  FROM (SELECT date_format(date_add('month', -1,
                 date_parse(cast(codmes AS varchar), '%Y%m')), '%Y%m')  AS codmes_mrm,
               max(cast(trf_f_t AS double))                             AS trf_f_t
          FROM d_perm_aws.scr_stk_ree_pp_cal_202607
         GROUP BY 1) v
  JOIN ft f ON f.codmes_mrm = v.codmes_mrm
