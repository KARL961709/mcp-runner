-- i05. Grano: duplicados por (codmes, tip_doc, key_value) y por (codmes, tip_doc, key_value, sub_producto). >0 en el 1o y 0 en el 2o = grano persona-mes-subproducto (una persona puede tener CDD y EC el mismo mes).
SELECT 'persona_mes' AS llave, COUNT(*) AS n_grupos_dup
FROM (SELECT CAST(codmes AS varchar) AS c, tip_doc, key_value
      FROM disc_model_owner.ds_ec_cdd_cal
      GROUP BY CAST(codmes AS varchar), tip_doc, key_value HAVING COUNT(*) > 1)
UNION ALL
SELECT 'persona_mes_subprod' AS llave, COUNT(*) AS n_grupos_dup
FROM (SELECT CAST(codmes AS varchar) AS c, tip_doc, key_value, sub_producto
      FROM disc_model_owner.ds_ec_cdd_cal
      GROUP BY CAST(codmes AS varchar), tip_doc, key_value, sub_producto HAVING COUNT(*) > 1)
