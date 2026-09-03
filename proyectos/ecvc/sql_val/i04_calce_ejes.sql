-- i04. Calce pd_raw vs RD12 por eje (IBK maduro scoreado) via GROUPING SETS: sub_producto, tipo_ingreso, nodo y global. Desajuste por eje.
SELECT sub_producto, tipo_ingreso, nodo,
       COUNT(*) AS n,
       ROUND(AVG(pd_raw), 5) AS pd_raw_avg,
       ROUND(AVG(CAST(target_12m AS double)), 5) AS rd12
FROM disc_model_owner.ds_ec_cdd_cal
WHERE flg_ibk = 1 AND flg_pd_raw = 1 AND target_12m IS NOT NULL
GROUP BY GROUPING SETS ((sub_producto), (tipo_ingreso), (nodo), ())
ORDER BY 1, 2, 3
