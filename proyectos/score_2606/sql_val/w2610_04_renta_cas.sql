-- w2610_04. Fuente de renta/tipo_ingreso del nodos (ds_rtd_rskvol_cas_ingr_ir) por numcarga.
--   numcarga=1 -> tipoing (periodo=origen=202610) y numcarga=2 -> casc renta (periodo=202610).
--   Ambos necesitan periodo=202610. Si max < 202610, tipo_ingreso/renta caen nulos en el build. Read-only.
SELECT
    CAST(numcarga AS varchar) AS numcarga,
    CAST(MAX(periodo) AS varchar) AS max_periodo,
    COUNT(*) AS n
FROM e_perm_aws.ds_rtd_rskvol_cas_ingr_ir
WHERE CAST(periodo AS varchar) >= '202608'
GROUP BY CAST(numcarga AS varchar)
ORDER BY numcarga
