-- 03 regla por t: inflacion base para el mes de ejecucion 202611 (esperado 16 filas de p_codmes 202609: 202603=2.57 202606=3.98 202609=4.43 202612=4.89 202703=4.93 202706=3.72 202709=2.82 202712=2.84 202803=2.63 202806=2.5 202809=2.5 202812=2.5 202903=2.5 202906=2.5 202909=2.5 202912=2.5)
WITH carga AS (
  SELECT p_codmes, MAX(nro_carga) AS nro_carga
  FROM disc_model_owner.macro_apoyo_proy
  WHERE p_codmes < '202611'
  GROUP BY p_codmes
  ORDER BY p_codmes DESC
  LIMIT 1
)
SELECT p.ticker, p.cod_mes, p.valor, p.p_codmes, p.nro_carga
FROM disc_model_owner.macro_apoyo_proy p
JOIN carga c ON c.p_codmes = p.p_codmes AND c.nro_carga = p.nro_carga
WHERE p.ticker = 'AP00025BQ'
ORDER BY p.cod_mes
