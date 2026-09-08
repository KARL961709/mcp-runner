-- 04_cobertura_bpe.sql | cobertura de user_desembolso en el ds del modelo Origen BPE (ds_adm_bpe_bankbn_cal_202607, que trae pd_raw y prob_modelo_cal): cuantos cliente-mes cruzan por (cod_tip_doc=tip_doc, key_value, cod_mes=codmes) match_exacto, y cuantos cruzan al menos como cliente ignorando el mes (match_cliente). Separa el problema de cobertura del de desalce de codmes, para decidir como traer la PD de Origen BPE. READ-ONLY
WITH ud AS (
  SELECT DISTINCT cast(cod_mes AS int) AS cm, cod_tip_doc AS td, key_value AS kv
  FROM d_perm_aws.user_desembolso
),
ds_cm AS (
  SELECT DISTINCT cast(codmes AS int) AS cm, tip_doc AS td, key_value AS kv
  FROM disc_model_owner.ds_adm_bpe_bankbn_cal_202607
),
ds_cli AS (
  SELECT DISTINCT tip_doc AS td, key_value AS kv
  FROM disc_model_owner.ds_adm_bpe_bankbn_cal_202607
)
SELECT
  count(*) AS ud_cli_mes,
  sum(CASE WHEN e.cm IS NOT NULL THEN 1 ELSE 0 END) AS match_exacto,
  round(100.0 * sum(CASE WHEN e.cm IS NOT NULL THEN 1 ELSE 0 END) / count(*), 2) AS pct_exacto,
  sum(CASE WHEN c.kv IS NOT NULL THEN 1 ELSE 0 END) AS match_cliente,
  round(100.0 * sum(CASE WHEN c.kv IS NOT NULL THEN 1 ELSE 0 END) / count(*), 2) AS pct_cliente
FROM ud
LEFT JOIN ds_cm  e ON e.cm = ud.cm AND e.td = ud.td AND e.kv = ud.kv
LEFT JOIN ds_cli c ON c.td = ud.td AND c.kv = ud.kv
