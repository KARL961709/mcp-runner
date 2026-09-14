-- 30_frontera_scr.sql | ultimo codmes (mes de negocio) y ultimo p_codmes (particion de descarga) de e_perm_aws.scr_admbankbpe_rsk, listando las parejas (codmes, p_codmes) del tramo final para ver la relacion en la frontera (se espera p_codmes = codmes+1) y hasta que mes llega el score. La fila de arriba es el ultimo codmes disponible. Solo conteos. READ-ONLY
SELECT cast(codmes AS int) AS codmes, cast(p_codmes AS int) AS p_codmes, count(*) AS n_filas
FROM e_perm_aws.scr_admbankbpe_rsk
WHERE probabilidad IS NOT NULL AND codmes >= '202603'
GROUP BY cast(codmes AS int), cast(p_codmes AS int)
ORDER BY codmes DESC, p_codmes DESC
