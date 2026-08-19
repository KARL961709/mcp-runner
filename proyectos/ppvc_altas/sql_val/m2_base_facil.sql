-- m2 | Valores de ca_nom_base_final DENTRO de '5.P FACIL' (jun/jul). READ-ONLY.
--   Por si CIMA (u otra campana a excluir) viene por el nombre de base y no por marca.
SELECT ca_nom_base_final, count(*) AS n
FROM d_perm_aws.t_dsmb_pp_7339
WHERE ca_periodo IN ('202606', '202607') AND sub_prod = '5.P FACIL'
GROUP BY ca_nom_base_final
ORDER BY 2 DESC
