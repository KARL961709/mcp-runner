-- =====================================================================================
-- CHECK_PROGRAMAS.sql | ¿siguen entrando clientes NUEVOS a Impulsa / Reactiva?
--
-- POR QUE IMPORTA
--   flg_impulsa original (q2_adv_prog_src L81) mira [m0, m0+12] — hacia ADELANTE.
--   FLAGS_DESDE_MADRE lo calcula backward [m0-12, m0], que si es implementable.
--   Las dos definiciones CONVERGEN si y solo si no hay ENTRADAS NUEVAS al programa:
--   sin desembolsos nuevos, la ventana forward no puede capturar a nadie que la
--   backward no capture ya (el saldo del programa persiste en el RCC mientras amortiza).
--
--   Este query mide ENTRADAS, no stock. Un stock que baja solo dice que amortiza;
--   lo que decide es si alguien PASA de 0 a >0.
--
-- LECTURA
--   entrantes = clientes con saldo del programa en el mes t y SIN saldo en t-1.
--   Si los ultimos ~12-18 meses dan 0 (o residual), la sustitucion backward<->forward
--   es inocua para cohortes futuras y el defecto 2 queda cerrado con evidencia.
--
-- READ-ONLY. Ajustar el rango si quieres mirar mas atras.
-- =====================================================================================

WITH r AS (
  SELECT tip_doc, key_value, cast(codmes AS int) AS codmes,
    sum(case when regexp_like(cod_cuenta_rcc,'^81.9520[1-9]|^81.95210') and saldo>0
             then saldo else 0 end) AS sld_impulsa,
    sum(case when substr(cod_cuenta_rcc,1,2)='81' and substr(cod_cuenta_rcc,4,1)='8'
              and substr(cod_cuenta_rcc,6,1) in ('1','3','4','5','6')
             then saldo else 0 end) AS sld_reactiva
  FROM e_perm_aws.t_fact_report_rcc_rsk
  WHERE p_codmes BETWEEN '202301' AND '202605'
    AND codmes   BETWEEN '202301' AND '202605'
  GROUP BY 1,2,3
),
lag1 AS (
  SELECT tip_doc, key_value, codmes, sld_impulsa, sld_reactiva,
    lag(sld_impulsa)  OVER (PARTITION BY tip_doc, key_value ORDER BY codmes) AS imp_prev,
    lag(sld_reactiva) OVER (PARTITION BY tip_doc, key_value ORDER BY codmes) AS rea_prev
  FROM r
)
SELECT codmes,
  count_if(sld_impulsa  > 0)                              AS stock_impulsa,
  count_if(sld_impulsa  > 0 AND coalesce(imp_prev,0) = 0) AS entrantes_impulsa,
  count_if(sld_reactiva > 0)                              AS stock_reactiva,
  count_if(sld_reactiva > 0 AND coalesce(rea_prev,0) = 0) AS entrantes_reactiva
FROM lag1
WHERE codmes >= 202401
GROUP BY codmes
ORDER BY codmes
