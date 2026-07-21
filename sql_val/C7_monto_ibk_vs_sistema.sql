-- =====================================================================================
-- ORIGEN BPE PD · V2 · VALIDACION (read-only)
--   archivo : C_calibra/C7_monto_ibk_vs_sistema.sql
--   origen  : ~\Documents\2026\GDM\Origen_BPE_PD_V2\_src\C7_monto_ibk_vs_sistema.sql
--   sha256  : 45a70e684e00   (del cuerpo, sin este encabezado)
--   estado  : ROJO
--   nota    : flg_monto hoy mide exposicion SISTEMA, no ticket IBK: cuanto cambia si se alinea
-- =====================================================================================
-- =====================================================================================
-- C7_monto_ibk_vs_sistema.sql | ¿cuanto cambia flg_monto si se mide en IBK y no en el sistema?
--
-- EL DEFECTO
--   'altas monitoreo.txt' — el generador de t_dan_mrm_admbankbpe_altas_rep — tiene DOS
--   agregaciones y publica la equivocada:
--     data_rcc       group by codmes, tip_doc, key_value, tipo_credito, cod_instit_financiera
--                    POR ENTIDAD  -> alimenta la deteccion de alta2
--     data_rcc_bank  group by codmes, tip_doc, key_value--, tipo_credito, cod_instit_financiera
--                    SIN ENTIDAD  -> alimenta saldo_m0..m12 y max_saldo de la TABLA PUBLICADA
--   La entidad esta comentada a proposito en la segunda.
--   => flg_monto hoy mide si el cliente debe 30k en TODO EL SISTEMA, no si IBK le presto 30k.
--   Como exposicion sistema >= exposicion IBK siempre, el filtro es DEMASIADO PERMISIVO.
--
-- LA REGLA CORREGIDA QUE SE PRUEBA AQUI
--   flg_monto_ibk = (max_saldo_sistema >= 30000 AND saldo_m0_ibk IN [10k, 30k))
--                    OR saldo_m0_ibk >= 30000
--   saldo_m0 SI puede y debe ser por entidad: es lo que IBK desembolso ese mes.
--   max_saldo NO puede: mira [m0-12, m0-1] y un alta se define porque NO tenia saldo en esa
--   entidad los meses previos — para un A-12 daria exactamente 0 y la pierna se apagaria sola.
--   Queda entonces: ticket propio de IBK, o ticket parcial + evidencia de tamanio en el sistema.
--
-- saldo_m0_ibk replica VERBATIM el saldo_m0_entidad del generador: tipo_credito 8-10,
-- tag IN (RESTO DD, DESCUENTOS, FACTORING, REFINANCIADOS, LC NO UTILIZADA, LC DESCUENTO),
-- ent_honrada=0 (trivial: '00002' no esta en la lista de honradas).
--
-- Ventana 202207-202505, sin impulsa ni reactiva_puro.
-- ~30 filas. READ-ONLY.
-- =====================================================================================

WITH rcc_ibk AS (
  SELECT codmes, tip_doc, key_value, tipo_credito, saldo,
         CASE WHEN substr(cod_cuenta_rcc,1,2)='14' AND substr(cod_cuenta_rcc,4,1) IN ('1','3','4','5','6') THEN
                CASE WHEN substr(cod_cuenta_rcc,7,2)='05' THEN 'DESCUENTOS'
                     WHEN substr(cod_cuenta_rcc,7,2)='10' THEN 'FACTORING'
                     WHEN substr(cod_cuenta_rcc,7,2)='04' THEN 'SOBREGIRO'
                     WHEN substr(cod_cuenta_rcc,7,2)='01' THEN 'AVANCE CC'
                     WHEN substr(cod_cuenta_rcc,4,1)='4'  THEN 'REFINANCIADOS'
                     ELSE 'RESTO DD' END
              WHEN substr(cod_cuenta_rcc,1,2)='72' AND substr(cod_cuenta_rcc,4,1)='5' THEN
                CASE WHEN substr(cod_cuenta_rcc,5,2)='02' THEN 'LC DESCUENTO'
                     WHEN substr(cod_cuenta_rcc,5,2) IN ('03','06','08','09') THEN 'LC NO UTILIZADA'
                     ELSE 'RESTO LC' END
              ELSE 'OTROS' END AS tg
  FROM e_perm_aws.t_fact_report_rcc_rsk
  WHERE p_codmes BETWEEN '202207' AND '202505'
    AND codmes   BETWEEN '202207' AND '202505'
    AND cod_instit_financiera = '00002'
),
s0 AS (
  SELECT codmes, tip_doc, key_value,
         sum(CASE WHEN cast(tipo_credito AS int) BETWEEN 8 AND 10
                   AND tg IN ('RESTO DD','DESCUENTOS','FACTORING','REFINANCIADOS',
                              'LC NO UTILIZADA','LC DESCUENTO')
                  THEN saldo ELSE 0 END) AS saldo_m0_ibk
  FROM rcc_ibk
  GROUP BY 1,2,3
),
a AS (
  SELECT cast(a.codmes AS int) AS codmes, a.personeria,
         cast(a.saldo_m0  AS double) AS s0_sistema,
         cast(a.max_saldo AS double) AS maxs_sistema,
         coalesce(i.saldo_m0_ibk, 0)  AS s0_ibk,
         coalesce(c.flg_monto, 0)     AS monto_hoy,
         cast(c.target_12m AS double) AS y,
         coalesce(c.flg_calib_m2, 0)  AS clean_hoy
  FROM disc_model_owner.bnbpe_ibk_calib_src c
  JOIN disc_model_owner.bnbpe_ibk_altas_src a
    ON a.codmes = c.codmes AND a.tip_doc = c.tip_doc AND a.key_value = c.key_value
  LEFT JOIN s0 i
    ON i.codmes = c.codmes AND i.tip_doc = c.tip_doc AND i.key_value = c.key_value
  WHERE c.flg_ibk = 1 AND c.top4_entidad = 'TOP4'
    AND coalesce(c.flg_impulsa,0) = 0 AND coalesce(c.flg_reactiva_puro,0) = 0
    AND cast(c.codmes AS int) BETWEEN 202207 AND 202505
),
r AS (
  SELECT *,
         CASE WHEN (maxs_sistema >= 30000 AND s0_ibk >= 10000 AND s0_ibk < 30000)
                OR s0_ibk >= 30000 THEN 1 ELSE 0 END AS monto_ibk
  FROM a
)

-- ------------------------------------------------- 1. cuanto se mueve
SELECT '1. MIGRACION' AS bloque,
       'hoy=' || cast(monto_hoy AS varchar) || ' -> ibk=' || cast(monto_ibk AS varchar) AS detalle,
       personeria,
       cast(count(*) AS varchar) AS n,
       cast(sum(y) AS varchar) AS def,
       cast(round(100.0 * avg(y), 2) AS varchar) || ' %' AS rd
FROM r GROUP BY monto_hoy, monto_ibk, personeria

-- ------------------------------------------------- 2. el filtro, antes y despues
UNION ALL
SELECT '2. FILTRO', 'monto=1 HOY (sistema)', personeria,
       cast(count_if(monto_hoy = 1) AS varchar),
       cast(sum(CASE WHEN monto_hoy = 1 THEN y ELSE 0 END) AS varchar),
       cast(round(100.0 * count_if(monto_hoy = 1) / nullif(count(*),0), 1) AS varchar) || ' % de la pob'
FROM r GROUP BY personeria
UNION ALL
SELECT '2. FILTRO', 'monto=1 con IBK', personeria,
       cast(count_if(monto_ibk = 1) AS varchar),
       cast(sum(CASE WHEN monto_ibk = 1 THEN y ELSE 0 END) AS varchar),
       cast(round(100.0 * count_if(monto_ibk = 1) / nullif(count(*),0), 1) AS varchar) || ' % de la pob'
FROM r GROUP BY personeria

-- ------------------------------------------------- 3. el clean, si el filtro se QUEDA
-- Es el escenario que decide si alinear a IBK es mas o menos conservador.
UNION ALL
SELECT '3. CLEAN SI SE QUEDA', 'clean HOY', personeria,
       cast(count_if(clean_hoy = 1) AS varchar),
       cast(sum(CASE WHEN clean_hoy = 1 THEN y ELSE 0 END) AS varchar),
       cast(round(100.0 * sum(CASE WHEN clean_hoy = 1 THEN y ELSE 0 END)
                / nullif(count_if(clean_hoy = 1), 0), 2) AS varchar) || ' %'
FROM r GROUP BY personeria
UNION ALL
SELECT '3. CLEAN SI SE QUEDA', 'clean con monto IBK', personeria,
       cast(count_if(clean_hoy = 1 AND monto_ibk = 1) AS varchar),
       cast(sum(CASE WHEN clean_hoy = 1 AND monto_ibk = 1 THEN y ELSE 0 END) AS varchar),
       cast(round(100.0 * sum(CASE WHEN clean_hoy = 1 AND monto_ibk = 1 THEN y ELSE 0 END)
                / nullif(count_if(clean_hoy = 1 AND monto_ibk = 1), 0), 2) AS varchar) || ' %'
FROM r GROUP BY personeria
UNION ALL
SELECT '3. CLEAN SI SE QUEDA', 'los que SALDRIAN del clean', personeria,
       cast(count_if(clean_hoy = 1 AND monto_ibk = 0) AS varchar),
       cast(sum(CASE WHEN clean_hoy = 1 AND monto_ibk = 0 THEN y ELSE 0 END) AS varchar),
       cast(round(100.0 * sum(CASE WHEN clean_hoy = 1 AND monto_ibk = 0 THEN y ELSE 0 END)
                / nullif(count_if(clean_hoy = 1 AND monto_ibk = 0), 0), 2) AS varchar) || ' %'
FROM r GROUP BY personeria

-- ------------------------------------------------- 4. cuanto se infla el saldo con el sistema
UNION ALL
SELECT '4. INFLADO', 'saldo_m0 sistema / IBK (mediana del ratio)', personeria,
       cast(count_if(s0_ibk > 0) AS varchar),
       cast(round(approx_percentile(CASE WHEN s0_ibk > 0 THEN s0_sistema / s0_ibk END, 0.5), 2) AS varchar),
       'p90 ' || cast(round(approx_percentile(CASE WHEN s0_ibk > 0 THEN s0_sistema / s0_ibk END, 0.9), 2) AS varchar)
FROM r GROUP BY personeria
UNION ALL
SELECT '4. INFLADO', 'altas con saldo_m0_ibk = 0', personeria,
       cast(count_if(s0_ibk = 0) AS varchar),
       cast(round(100.0 * count_if(s0_ibk = 0) / nullif(count(*),0), 2) AS varchar) || ' %',
       'OJO: un alta IBK sin saldo IBK en m0 no deberia existir'
FROM r GROUP BY personeria

ORDER BY 1, 2, 3
