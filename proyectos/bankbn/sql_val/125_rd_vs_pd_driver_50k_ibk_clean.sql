-- 125_rd_vs_pd_driver_50k_ibk_clean.sql | igual que 122 (IBK, ticket saldo_m0>=50k) pero capa CLEAN-SOLO: flg_clean_calib = 1 (reproduce la hoja 2_solo_clean del original). Grano personeria x codmes, rd01..rd12. READ-ONLY
WITH po AS (
  SELECT cast(codmes AS int) AS codmes, tip_doc, key_value,
         max(cast(saldo_m0_ent AS double)) AS s0
  FROM disc_model_owner.ds_adm_bpe_bankbn_po
  WHERE marca_entidad = 'IBK'
  GROUP BY cast(codmes AS int), tip_doc, key_value
),
q AS (
  SELECT CASE WHEN c.flg_ppjj = 1 THEN 'PJJ' ELSE 'PNN' END AS driver,
         cast(c.codmes AS int) AS codmes,
         CASE WHEN date_diff('month', date_parse(CAST(c.codmes AS VARCHAR), '%Y%m'), date_parse('202606', '%Y%m')) >= 12 THEN 'SI' ELSE 'NO' END AS maduro,
         date_diff('month', date_parse(CAST(c.codmes AS VARCHAR), '%Y%m'), date_parse('202606', '%Y%m')) AS h_disp,
         TRY_CAST(c.fhat AS DOUBLE) AS fhat,
         TRY_CAST(c.pd_raw AS DOUBLE) AS pd_crudo,
         TRY_CAST(c.prob_modelo_cal AS DOUBLE) AS pd_pit,
         TRY_CAST(c.target_01m AS INTEGER) AS t01, TRY_CAST(c.target_02m AS INTEGER) AS t02,
         TRY_CAST(c.target_03m AS INTEGER) AS t03, TRY_CAST(c.target_04m AS INTEGER) AS t04,
         TRY_CAST(c.target_05m AS INTEGER) AS t05, TRY_CAST(c.target_06m AS INTEGER) AS t06,
         TRY_CAST(c.target_07m AS INTEGER) AS t07, TRY_CAST(c.target_08m AS INTEGER) AS t08,
         TRY_CAST(c.target_09m AS INTEGER) AS t09, TRY_CAST(c.target_10m AS INTEGER) AS t10,
         TRY_CAST(c.target_11m AS INTEGER) AS t11, TRY_CAST(c.target_12m AS INTEGER) AS t12
  FROM disc_model_owner.ds_adm_bpe_bankbn_cal_202607 c
  JOIN po p ON p.codmes = cast(c.codmes AS int) AND p.tip_doc = c.tip_doc AND p.key_value = c.key_value
  WHERE c.entidad = 'IBK' AND c.pd_raw IS NOT NULL AND c.fhat IS NOT NULL AND c.flg_clean_calib = 1
    AND p.s0 >= 50000
)
SELECT 'IBK' AS poblacion, driver, codmes, maduro, h_disp,
       count(*) AS n, count(t12) AS n_target, round(avg(fhat), 6) AS fhat,
       round(100.0 * avg(pd_crudo), 4) AS pd_raw_pct,
       round(100.0 * avg(pd_pit), 4) AS pd_pit_pct,
       round(100.0 * avg(CAST(t01 AS DOUBLE)), 4) AS rd01, round(100.0 * avg(CAST(t02 AS DOUBLE)), 4) AS rd02,
       round(100.0 * avg(CAST(t03 AS DOUBLE)), 4) AS rd03, round(100.0 * avg(CAST(t04 AS DOUBLE)), 4) AS rd04,
       round(100.0 * avg(CAST(t05 AS DOUBLE)), 4) AS rd05, round(100.0 * avg(CAST(t06 AS DOUBLE)), 4) AS rd06,
       round(100.0 * avg(CAST(t07 AS DOUBLE)), 4) AS rd07, round(100.0 * avg(CAST(t08 AS DOUBLE)), 4) AS rd08,
       round(100.0 * avg(CAST(t09 AS DOUBLE)), 4) AS rd09, round(100.0 * avg(CAST(t10 AS DOUBLE)), 4) AS rd10,
       round(100.0 * avg(CAST(t11 AS DOUBLE)), 4) AS rd11, round(100.0 * avg(CAST(t12 AS DOUBLE)), 4) AS rd12
FROM q
GROUP BY driver, codmes, maduro, h_disp
ORDER BY driver, codmes
