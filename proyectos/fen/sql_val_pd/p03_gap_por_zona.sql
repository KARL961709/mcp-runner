-- p03 LA CONSULTA QUE IMPORTA — ¿el modelo se queda corto donde pega el FEN?
--
-- No estima nada nuevo: usa la PD que el modelo YA predijo y la compara con lo observado.
-- Si el gap (observado - predicho) crece con el nivel R, ese exceso es el efecto FEN
-- que la calibración nacional no ve. Eso es gamma, leído directo del dato.
--
-- Salida: una fila por nivel R x año. ~24 filas. Sin identificadores de cliente.
-- OJO: ajustar los nombres de columna de RENIEC según lo que devuelva p02.
WITH base AS (
  SELECT trim(s.key_value)      AS kv,
         substr(s.cod_mes, 1, 4) AS anio,
         s.cod_mes               AS codmes,
         s.prob_modelo_cal_ppfacil AS pd_pred,
         CAST(t.flg_target_pp_12m AS DOUBLE) AS obs
  FROM disc_model_owner.scr_origenpp_altas_backtest s
  JOIN disc_model_owner.ds_po_origpp_CS_cal_final t
    ON trim(s.key_value) = trim(t.id_value)
   AND trim(s.cod_tip_doc) = trim(CAST(t.tip_doc AS VARCHAR))
   AND s.cod_mes = CAST(t.codmes AS VARCHAR)
  WHERE t.flg_calib = 1
    AND t.subproducto_ = '5.P FACIL'
    AND s.prob_modelo_cal_ppfacil IS NOT NULL
),
geo AS (   -- RENIEC: 98,08 % de admisión (medido). Ajustar nombres si p02 dice otra cosa.
  SELECT trim(key_value) AS kv,
         regexp_replace(normalize(upper(trim(departamento)), NFD), '\p{M}', '') AS dep,
         regexp_replace(normalize(upper(trim(provincia)),    NFD), '\p{M}', '') AS prov,
         regexp_replace(normalize(upper(trim(distrito)),     NFD), '\p{M}', '') AS dist
  FROM e_perm_aws.t_mst_reniec_rsk
),
fen AS (
  SELECT regexp_replace(normalize(upper(trim(departamento)), NFD), '\p{M}', '') AS dep,
         regexp_replace(normalize(upper(trim(provincia)),    NFD), '\p{M}', '') AS prov,
         regexp_replace(normalize(upper(trim(distrito)),     NFD), '\p{M}', '') AS dist,
         r_label
  FROM disc_model_owner.fen_score_v5
),
j AS (
  SELECT b.anio,
         COALESCE(f.r_label, 'SIN_GEO') AS zona,
         b.pd_pred, b.obs
  FROM base b
  LEFT JOIN geo g ON b.kv = g.kv
  LEFT JOIN fen f ON g.dep = f.dep AND g.prov = f.prov AND g.dist = f.dist
)
SELECT zona,
       anio,
       count(*)                              AS n,
       round(avg(pd_pred) * 100, 3)          AS pd_predicha_pct,
       round(avg(obs)     * 100, 3)          AS rd_observada_pct,
       round((avg(obs) - avg(pd_pred)) * 10000, 0) AS gap_bps
FROM j
GROUP BY zona, anio
ORDER BY zona, anio
