-- g04 hazard calendario x banda R (R0 no-pac / R1-3 / R4-5) — el fisico R spikea en la ventana FEN?
WITH j AS (
  SELECT CASE WHEN r.r_label_reest='R0' THEN 'R0' WHEN r.r_label_reest IN ('R1','R2','R3') THEN 'R123' WHEN r.r_label_reest IN ('R4','R5') THEN 'R45' END AS expo, c.codmes,
    array[c.target_01m,c.target_02m,c.target_03m,c.target_04m,c.target_05m,c.target_06m,c.target_07m,c.target_08m,c.target_09m,c.target_10m,c.target_11m,c.target_12m] AS tgt
  FROM disc_model_owner.ds_adm_pp_cdpp_cal c
  JOIN disc_model_owner.mca_bd_reniec_xy_r_reest r ON c.key_value=r.key_value
  WHERE c.flg_ibk=1 AND c.flg_clean=1 AND c.sub_producto IN ('PP_CD','PP_FACIL') AND c.codmes>='202101' AND r.r_label_reest IS NOT NULL
),
u AS (
  SELECT expo, date_format(date_add('month',k,date_parse(codmes||'01','%Y%m%d')),'%Y%m') AS cal_mes,
    element_at(tgt,k) AS cum, CASE WHEN k=1 THEN 0 ELSE element_at(tgt,k-1) END AS cum_prev
  FROM j CROSS JOIN UNNEST(sequence(1,12)) AS x(k)
)
SELECT cal_mes, expo,
  sum(CASE WHEN cum_prev=0 THEN 1 ELSE 0 END) AS at_risk,
  round(1e0*sum(CASE WHEN cum=1 AND cum_prev=0 THEN 1 ELSE 0 END)/nullif(sum(CASE WHEN cum_prev=0 THEN 1 ELSE 0 END),0),5) AS hazard
FROM u WHERE cum IS NOT NULL AND cal_mes BETWEEN '202201' AND '202607'
GROUP BY cal_mes, expo ORDER BY cal_mes, expo
