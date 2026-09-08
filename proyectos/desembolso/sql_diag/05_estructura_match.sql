-- 05_estructura_match.sql | estructura del cruce user_desembolso vs ds Origen BPE por producto: % match exacto (mismo codmes), % como cliente (cualquier mes), y direccion temporal de la alta BPE respecto al desembolso (antes_igual = alta con codmes <= mes del desembolso, sirve para as-of sin look-ahead, y despues = alta posterior que seria look-ahead). Decide como traer el pd_raw crudo por producto. READ-ONLY
WITH ud AS (
  SELECT DISTINCT cast(cod_mes AS int) AS cm, cod_tip_doc AS td, key_value AS kv, desc_producto AS prod
  FROM d_perm_aws.user_desembolso
),
ds AS (
  SELECT tip_doc AS td, key_value AS kv, cast(codmes AS int) AS dcm
  FROM disc_model_owner.ds_adm_bpe_bankbn_cal_202607
),
j AS (
  SELECT ud.prod, ud.cm, ud.td, ud.kv,
    max(CASE WHEN d.dcm = ud.cm THEN 1 ELSE 0 END) AS m_exacto,
    max(CASE WHEN d.dcm IS NOT NULL THEN 1 ELSE 0 END) AS m_cli,
    max(CASE WHEN d.dcm <= ud.cm THEN 1 ELSE 0 END) AS m_asof,
    max(CASE WHEN d.dcm > ud.cm THEN 1 ELSE 0 END) AS m_post
  FROM ud
  LEFT JOIN ds d ON d.td = ud.td AND d.kv = ud.kv
  GROUP BY ud.prod, ud.cm, ud.td, ud.kv
)
SELECT prod,
  count(*) AS n_cli_mes,
  round(100.0 * avg(m_exacto), 1) AS pct_exacto,
  round(100.0 * avg(m_cli), 1) AS pct_cliente,
  round(100.0 * avg(m_asof), 1) AS pct_asof_antes_igual,
  round(100.0 * avg(m_post), 1) AS pct_solo_post
FROM j
GROUP BY prod
ORDER BY n_cli_mes DESC
