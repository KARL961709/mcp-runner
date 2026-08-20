-- 121_saldo_mensual.sql | detalle MENSUAL del eje saldo. Por codmes y personeria: volumen (n), % chico (<30k), RD total, RD chico (<30k) vs grande (>=75k), y sobrevivientes a piso 30k/75k con su RD. Complementa 120 (que agrega por anio). Lee _cal (target/flg_ppjj/flg_calib) + _po (max_saldo_ent, marca_entidad=IBK), RD madura. Read-only, ~70 filas
WITH po AS (
  SELECT cast(codmes AS int) AS codmes, tip_doc, key_value,
         max(cast(max_saldo_ent AS double)) AS maxs
  FROM disc_model_owner.ds_adm_bpe_bankbn_po
  WHERE marca_entidad = 'IBK'
  GROUP BY cast(codmes AS int), tip_doc, key_value
),
r AS (
  SELECT cast(c.codmes AS int) AS codmes,
         CASE WHEN coalesce(c.flg_ppjj, 0) = 1 THEN 'PJJ' ELSE 'PNN' END AS personeria,
         cast(c.target_12m AS double) AS y,
         p.maxs
  FROM disc_model_owner.ds_adm_bpe_bankbn_cal c
  JOIN po p
    ON p.codmes = cast(c.codmes AS int) AND p.tip_doc = c.tip_doc AND p.key_value = c.key_value
  WHERE c.entidad = 'IBK' AND coalesce(c.flg_calib, 0) = 1 AND c.target_12m IS NOT NULL
)

SELECT codmes,
       personeria,
       count(*)                                                                         AS n,
       round(100.0 * count_if(maxs < 30000) / nullif(count(*), 0), 1)                   AS pct_chico,
       round(100.0 * avg(y), 2)                                                         AS rd_total,
       round(100.0 * avg(CASE WHEN maxs < 30000 THEN y END), 2)                         AS rd_chico,
       round(100.0 * avg(CASE WHEN maxs >= 75000 THEN y END), 2)                        AS rd_grande,
       count_if(maxs >= 30000)                                                          AS n_30k,
       round(100.0 * avg(CASE WHEN maxs >= 30000 THEN y END), 2)                        AS rd_30k,
       count_if(maxs >= 75000)                                                          AS n_75k,
       round(100.0 * avg(CASE WHEN maxs >= 75000 THEN y END), 2)                        AS rd_75k
FROM r
GROUP BY codmes, personeria
ORDER BY codmes, personeria
