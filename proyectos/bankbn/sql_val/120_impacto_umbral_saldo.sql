-- 120_impacto_umbral_saldo.sql | impacto de anadir un PISO de saldo (30/50/75/100k sobre max_saldo_ent) a la poblacion de calibracion IBK. El filtro_saldo vigente es por tipo_credito con techo 1M (piso 10k solo micro), NO tiene piso general: esto mide que pasaria si se agrega uno. Lee _cal (target/flg_ppjj/flg_calib) + _po (saldo_m0_ent/max_saldo_ent, marca_entidad=IBK). Da N, cobertura y RD por personeria a cada piso, el tramo que se cae, y RD chico vs grande por anio (hipotesis composicion-por-monto). Read-only, ~35 filas
WITH po AS (
  SELECT cast(codmes AS int) AS codmes, tip_doc, key_value,
         max(cast(saldo_m0_ent  AS double)) AS s0,
         max(cast(max_saldo_ent AS double)) AS maxs
  FROM disc_model_owner.ds_adm_bpe_bankbn_po
  WHERE marca_entidad = 'IBK'
  GROUP BY cast(codmes AS int), tip_doc, key_value
),
a AS (
  SELECT cast(c.codmes AS int) AS codmes,
         CASE WHEN coalesce(c.flg_ppjj, 0) = 1 THEN 'PJJ' ELSE 'PNN' END AS personeria,
         cast(c.target_12m AS double) AS y,
         p.s0, p.maxs
  FROM disc_model_owner.ds_adm_bpe_bankbn_cal c
  JOIN po p
    ON p.codmes = cast(c.codmes AS int) AND p.tip_doc = c.tip_doc AND p.key_value = c.key_value
  WHERE c.entidad = 'IBK' AND coalesce(c.flg_calib, 0) = 1 AND c.target_12m IS NOT NULL
),
r AS (
  SELECT *,
    CASE WHEN maxs >= 30000  THEN 1 ELSE 0 END AS m30,
    CASE WHEN maxs >= 50000  THEN 1 ELSE 0 END AS m50,
    CASE WHEN maxs >= 75000  THEN 1 ELSE 0 END AS m75,
    CASE WHEN maxs >= 100000 THEN 1 ELSE 0 END AS m100
  FROM a
)

-- ------------------------------------------------- 1. poblacion que SOBREVIVE cada piso (sobre max_saldo)
SELECT '1. PISO 30k' AS bloque, personeria,
       cast(count_if(m30 = 1) AS varchar) AS n,
       cast(round(100.0 * count_if(m30 = 1) / nullif(count(*), 0), 1) AS varchar) || ' % pob' AS cobertura,
       'RD ' || cast(round(100.0 * sum(CASE WHEN m30 = 1 THEN y END) / nullif(count_if(m30 = 1), 0), 2) AS varchar) || ' %' AS rd
FROM r GROUP BY personeria
UNION ALL
SELECT '2. PISO 50k', personeria,
       cast(count_if(m50 = 1) AS varchar),
       cast(round(100.0 * count_if(m50 = 1) / nullif(count(*), 0), 1) AS varchar) || ' % pob',
       'RD ' || cast(round(100.0 * sum(CASE WHEN m50 = 1 THEN y END) / nullif(count_if(m50 = 1), 0), 2) AS varchar) || ' %'
FROM r GROUP BY personeria
UNION ALL
SELECT '3. PISO 75k', personeria,
       cast(count_if(m75 = 1) AS varchar),
       cast(round(100.0 * count_if(m75 = 1) / nullif(count(*), 0), 1) AS varchar) || ' % pob',
       'RD ' || cast(round(100.0 * sum(CASE WHEN m75 = 1 THEN y END) / nullif(count_if(m75 = 1), 0), 2) AS varchar) || ' %'
FROM r GROUP BY personeria
UNION ALL
SELECT '4. PISO 100k', personeria,
       cast(count_if(m100 = 1) AS varchar),
       cast(round(100.0 * count_if(m100 = 1) / nullif(count(*), 0), 1) AS varchar) || ' % pob',
       'RD ' || cast(round(100.0 * sum(CASE WHEN m100 = 1 THEN y END) / nullif(count_if(m100 = 1), 0), 2) AS varchar) || ' %'
FROM r GROUP BY personeria

-- ------------------------------------------------- 2. tramo que se CAE al pasar de 30k a 75k
UNION ALL
SELECT '5. SALE 30->75k', personeria,
       cast(count_if(m30 = 1 AND m75 = 0) AS varchar),
       'def ' || cast(sum(CASE WHEN m30 = 1 AND m75 = 0 THEN y ELSE 0 END) AS varchar),
       'RD ' || cast(round(100.0 * sum(CASE WHEN m30 = 1 AND m75 = 0 THEN y END) / nullif(count_if(m30 = 1 AND m75 = 0), 0), 2) AS varchar) || ' %'
FROM r GROUP BY personeria

-- ------------------------------------------------- 3. composicion por anio: RD chico vs grande
UNION ALL
SELECT '6. COMP ' || cast(cast(codmes / 100 AS int) AS varchar), personeria,
       cast(count(*) AS varchar),
       cast(round(100.0 * count_if(maxs < 30000) / nullif(count(*), 0), 1) AS varchar) || ' % <30k',
       'RD <30k ' || cast(round(100.0 * sum(CASE WHEN maxs < 30000 THEN y END) / nullif(count_if(maxs < 30000), 0), 2) AS varchar)
       || ' % vs >=75k ' || cast(round(100.0 * sum(CASE WHEN maxs >= 75000 THEN y END) / nullif(count_if(maxs >= 75000), 0), 2) AS varchar) || ' %'
FROM r GROUP BY cast(codmes / 100 AS int), personeria

ORDER BY 1, 2
