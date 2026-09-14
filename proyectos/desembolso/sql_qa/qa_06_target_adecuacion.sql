-- qa_06_target_adecuacion.sql | confirma que la target del insumo b46029_desemb_cal_202609 es ADECUADA, todo desde la tabla ya creada (no relee la RCC). READ-ONLY. Bloque A madurez: por horizonte, cuantas filas quedan NULL por inmadurez (no cerradas contra la frontera) vs evaluables, y la RD sobre las evaluables, para probar que los horizontes no cerrados NO se censuran como 0. Bloque B hazard: sobre la cohorte madura a 12m (meses_madurez=12) la RD acumulada por horizonte 1..12, debe salir monotona creciente y de magnitud plausible. Bloque C segmento: RD a 12m de la cohorte madura por personeria (2=PJJ) y por producto. Formato largo, una fila por chequeo
WITH long AS (
  SELECT cod_tip_doc, desc_producto, meses_madurez, x.h AS h, x.t AS t
  FROM disc_model_owner.b46029_desemb_cal_202609
  CROSS JOIN UNNEST(
    ARRAY[1,2,3,4,5,6,7,8,9,10,11,12],
    ARRAY[target_01m,target_02m,target_03m,target_04m,target_05m,target_06m,target_07m,target_08m,target_09m,target_10m,target_11m,target_12m]
  ) AS x(h, t)
)
SELECT bloque, clave, n, malos, rd_pct, extra FROM (
  SELECT 'A madurez' AS bloque, lpad(cast(h AS varchar), 2, '0') AS clave,
    count(*) AS n,
    sum(CASE WHEN t = 1 THEN 1 ELSE 0 END) AS malos,
    round(100.0 * sum(CASE WHEN t = 1 THEN 1 ELSE 0 END) / nullif(sum(CASE WHEN t IS NOT NULL THEN 1 ELSE 0 END), 0), 3) AS rd_pct,
    concat('inmaduros_null=', cast(sum(CASE WHEN t IS NULL THEN 1 ELSE 0 END) AS varchar), ' evaluables=', cast(sum(CASE WHEN t IS NOT NULL THEN 1 ELSE 0 END) AS varchar)) AS extra
  FROM long GROUP BY h
  UNION ALL
  SELECT 'B hazard m12', lpad(cast(h AS varchar), 2, '0'),
    count(*), sum(t),
    round(100.0 * sum(t) / nullif(count(*), 0), 3),
    ''
  FROM long WHERE meses_madurez = 12 GROUP BY h
  UNION ALL
  SELECT 'C per m12', CASE WHEN cod_tip_doc = '2' THEN 'PJJ' ELSE 'PNN' END,
    count(*), sum(target_12m),
    round(100.0 * sum(target_12m) / nullif(count(*), 0), 3),
    ''
  FROM disc_model_owner.b46029_desemb_cal_202609 WHERE meses_madurez = 12 GROUP BY CASE WHEN cod_tip_doc = '2' THEN 'PJJ' ELSE 'PNN' END
  UNION ALL
  SELECT 'C prod m12', desc_producto,
    count(*), sum(target_12m),
    round(100.0 * sum(target_12m) / nullif(count(*), 0), 3),
    ''
  FROM disc_model_owner.b46029_desemb_cal_202609 WHERE meses_madurez = 12 GROUP BY desc_producto
) q
ORDER BY bloque, clave
