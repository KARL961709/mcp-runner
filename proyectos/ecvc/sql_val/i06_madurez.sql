-- i06. Frontera de madurez por horizonte y codmes: n maduros en target_03m/06m/09m/12m. Confirma el corte NULL escalonado (12m maduro hasta 202507).
SELECT CAST(codmes AS varchar) AS codmes,
       COUNT(*) AS n,
       SUM(CASE WHEN target_03m IS NOT NULL THEN 1 ELSE 0 END) AS mad03,
       SUM(CASE WHEN target_06m IS NOT NULL THEN 1 ELSE 0 END) AS mad06,
       SUM(CASE WHEN target_09m IS NOT NULL THEN 1 ELSE 0 END) AS mad09,
       SUM(CASE WHEN target_12m IS NOT NULL THEN 1 ELSE 0 END) AS mad12
FROM disc_model_owner.ds_ec_cdd_cal
GROUP BY CAST(codmes AS varchar)
ORDER BY 1
