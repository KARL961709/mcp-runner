-- 10_flg1_offset_ok.sql | SOLO flg_desembolso=1, con el OFFSET CORRECTO +1 (verificado en 09: score_codmes = p_codmes + 1). Por cod_mes: n_flg1, n_orig = score de origen exacto (score_codmes = cod_mes, o sea p_codmes = cod_mes - 1), n_asof = score con score_codmes menor o igual al mes del desembolso (el mas cercano, sin look-ahead ahora si correcto), pct_asof y pd_raw medio. Reemplaza a la 08 que cruzaba con offset 0. READ-ONLY
WITH ud AS (
  SELECT DISTINCT cast(cod_mes AS int) AS cm, cod_tip_doc AS td, key_value AS kv
  FROM d_perm_aws.user_desembolso
  WHERE flg_desembolso = 1
),
scr AS (
  SELECT cast(tip_doc AS varchar) AS td, key_value AS kv,
         cast(date_format(date_parse(cast(p_codmes AS varchar), '%Y%m') + interval '1' month, '%Y%m') AS int) AS scm,
         max(cast(probabilidad AS double)) AS pdr
  FROM e_perm_aws.scr_admbankbpe_rsk
  WHERE probabilidad IS NOT NULL AND p_codmes BETWEEN '202001' AND '202608'
  GROUP BY cast(tip_doc AS varchar), key_value,
           cast(date_format(date_parse(cast(p_codmes AS varchar), '%Y%m') + interval '1' month, '%Y%m') AS int)
),
cli AS (
  SELECT ud.cm, ud.td, ud.kv,
    max(CASE WHEN s.scm = ud.cm THEN 1 ELSE 0 END) AS m_orig,
    max(CASE WHEN s.scm <= ud.cm THEN s.scm END) AS best_scm
  FROM ud
  LEFT JOIN scr s ON s.td = ud.td AND s.kv = ud.kv
  GROUP BY ud.cm, ud.td, ud.kv
),
wp AS (
  SELECT c.cm, c.td, c.kv, c.m_orig, c.best_scm, s.pdr
  FROM cli c
  LEFT JOIN scr s ON s.td = c.td AND s.kv = c.kv AND s.scm = c.best_scm
)
SELECT cm AS cod_mes,
  count(*) AS n_flg1,
  sum(m_orig) AS n_orig_exacto,
  sum(CASE WHEN best_scm IS NOT NULL THEN 1 ELSE 0 END) AS n_asof,
  round(100.0 * sum(CASE WHEN best_scm IS NOT NULL THEN 1 ELSE 0 END) / count(*), 1) AS pct_asof,
  round(100.0 * avg(pdr), 3) AS pd_raw_medio_pct
FROM wp
GROUP BY cm
ORDER BY cm
