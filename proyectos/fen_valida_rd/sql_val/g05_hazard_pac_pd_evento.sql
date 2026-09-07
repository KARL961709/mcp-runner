-- g05 hazard x Pacifico x tercil pd_raw, SOLO ventanas de evento (Yaku 2023-03..08 y FEN 2026-03..07) — DiD controlado por PD
WITH j AS (
  SELECT CASE WHEN r.r_nivel_reest>=1 THEN 'PAC' ELSE 'NOPAC' END AS expo, c.codmes, c.pd_raw,
    array[c.target_01m,c.target_02m,c.target_03m,c.target_04m,c.target_05m,c.target_06m,c.target_07m,c.target_08m,c.target_09m,c.target_10m,c.target_11m,c.target_12m] AS tgt
  FROM disc_model_owner.ds_adm_pp_cdpp_cal c
  JOIN disc_model_owner.mca_bd_reniec_xy_r_reest r ON c.key_value=r.key_value
  WHERE c.flg_ibk=1 AND c.flg_clean=1 AND c.sub_producto IN ('PP_CD','PP_FACIL') AND c.codmes>='202101'
),
b AS (SELECT expo, codmes, tgt, ntile(3) OVER (ORDER BY pd_raw) AS pd_ter FROM j),
u AS (
  SELECT expo, pd_ter, date_format(date_add('month',k,date_parse(codmes||'01','%Y%m%d')),'%Y%m') AS cal_mes,
    element_at(tgt,k) AS cum, CASE WHEN k=1 THEN 0 ELSE element_at(tgt,k-1) END AS cum_prev
  FROM b CROSS JOIN UNNEST(sequence(1,12)) AS x(k)
)
SELECT CASE WHEN cal_mes BETWEEN '202303' AND '202308' THEN 'YAKU23' ELSE 'FEN26' END AS evento, pd_ter, expo,
  sum(CASE WHEN cum_prev=0 THEN 1 ELSE 0 END) AS at_risk,
  round(1e0*sum(CASE WHEN cum=1 AND cum_prev=0 THEN 1 ELSE 0 END)/nullif(sum(CASE WHEN cum_prev=0 THEN 1 ELSE 0 END),0),5) AS hazard
FROM u WHERE cum IS NOT NULL AND (cal_mes BETWEEN '202303' AND '202308' OR cal_mes BETWEEN '202603' AND '202607')
GROUP BY 1, pd_ter, expo ORDER BY 1, pd_ter, expo
