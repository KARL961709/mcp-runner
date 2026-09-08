-- qa_07_grano_cliente.sql | EL GRANO. La base es cod_mes x tip_doc x key_value x desc_producto,
-- pero el target se pega SOLO por cod_mes x tip_doc x key_value: un cliente con dos productos en
-- el mes recibe el MISMO target dos veces. La RD por filas entonces pondera por numero de
-- productos, no por clientes. Esto mide cuanto pesa esa diferencia antes de elegir el grano de
-- calibracion. READ-ONLY
SELECT cast(cod_mes / 100 AS int)                                                       AS anio,
  count(*)                                                                              AS filas,
  count(DISTINCT cod_tip_doc || '|' || cast(cod_mes AS varchar) || '|' || key_value)    AS clientes_mes,
  round(1.0 * count(*)
        / nullif(count(DISTINCT cod_tip_doc || '|' || cast(cod_mes AS varchar) || '|' || key_value), 0), 4) AS filas_por_cliente,
  round(100.0 * avg(cast(target_12m AS double)), 3)                                     AS rd_por_filas,
  round(100.0 * avg(cast(target_12m AS double))
        - 100.0 * sum(cast(target_12m AS double))
          / nullif(count(DISTINCT cod_tip_doc || '|' || cast(cod_mes AS varchar) || '|' || key_value), 0), 3) AS sesgo_aprox_pp
FROM disc_model_owner.b46029_desemb_cal_202609
WHERE meses_madurez = 12
GROUP BY cast(cod_mes / 100 AS int)
ORDER BY anio
