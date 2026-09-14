-- 29_modelos_scr.sql | lista los valores de modelo (y segmento) en e_perm_aws.scr_admbankbpe_rsk para confirmar que se aplica UN solo modelo (ADMBANKBPE) y decidir si hay que filtrar modelo explicito en el cruce del pd_raw. Ventana de los desembolsos. Solo conteos. READ-ONLY
SELECT modelo, segmento,
  count(*) AS n_filas,
  count(DISTINCT codmes) AS n_meses,
  count(DISTINCT key_value) AS n_clientes
FROM e_perm_aws.scr_admbankbpe_rsk
WHERE probabilidad IS NOT NULL AND codmes BETWEEN '202301' AND '202608'
GROUP BY modelo, segmento
ORDER BY n_filas DESC
