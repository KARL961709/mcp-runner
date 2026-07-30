-- b03 PARTICIONES del puente cod_cuc -> key_value -- particiona por fecinformacion, no codmes
SELECT fecinformacion
FROM "e_perm_aws"."scr_comportc_rsk$partitions"
ORDER BY 1 DESC
LIMIT 12
