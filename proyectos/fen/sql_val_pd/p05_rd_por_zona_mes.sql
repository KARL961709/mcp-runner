-- p05 RD OBSERVADA POR ZONA DE EXPOSICIÓN Y MES — la que estima gamma.
--
-- Usa flg_calib_rd (no flg_calib): NO exige score, así que llega hasta 201901.
-- Eso importa porque en la ventana Yaku (202301-202303) todavía no había score.
--
-- Identificación: diferencia en diferencias.
--   gamma  <-  [RD(R4-R5, Yaku) - RD(R4-R5, base)] - [RD(R0, Yaku) - RD(R0, base)]
-- El ciclo nacional y el cambio de score se cancelan en la segunda resta: aplican a
-- todas las zonas por igual. Lo que sobrevive es geográfico y del evento.
--
-- Salida: zona x mes. Sin identificadores de cliente.
-- Ajustar nombres de RENIEC según lo que devuelva p02, y la tabla PO según p04.
WITH po AS (
  SELECT trim(id_value)            AS kv,
         CAST(codmes AS VARCHAR)   AS codmes,
         CAST(flg_target_pp_12m AS DOUBLE) AS obs
  FROM disc_model_owner.pp_vc_ds_po_origpp
  WHERE flg_calib_rd = 1
    AND subproducto_ = '5.P FACIL'
    AND flg_target_pp_12m IS NOT NULL
),
geo AS (
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
  SELECT p.codmes,
         CASE WHEN f.r_label IN ('R4','R5') THEN '3_R4R5'
              WHEN f.r_label = 'R3'         THEN '2_R3'
              WHEN f.r_label IN ('R1','R2') THEN '1_R1R2'
              WHEN f.r_label = 'R0'         THEN '0_R0'
              ELSE '9_SIN_GEO' END AS zona,
         p.obs
  FROM po p
  LEFT JOIN geo g ON p.kv = g.kv
  LEFT JOIN fen f ON g.dep = f.dep AND g.prov = f.prov AND g.dist = f.dist
)
SELECT codmes,
       zona,
       count(*)                        AS n_altas,
       round(avg(obs) * 100, 3)        AS rd_12m_pct
FROM j
WHERE codmes BETWEEN '202101' AND '202412'
GROUP BY codmes, zona
HAVING count(*) >= 30
ORDER BY codmes, zona
