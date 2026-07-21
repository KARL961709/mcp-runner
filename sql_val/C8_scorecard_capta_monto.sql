-- =====================================================================================
-- ORIGEN BPE PD · V2 · VALIDACION (read-only)
--   archivo : C_calibra/C8_scorecard_capta_monto.sql
--   origen  : ~\Documents\2026\GDM\Origen_BPE_PD_V2\_src\C8_scorecard_capta_monto.sql
--   sha256  : 8a9532d04783   (del cuerpo, sin este encabezado)
--   estado  : ROJO
--   nota    : EL GATE: el pd_raw ya recoge el gradiente por ticket, o hay brecha de discriminacion
-- =====================================================================================
-- =====================================================================================
-- C8_scorecard_capta_monto.sql | ¿el pd_raw ya recoge el gradiente de riesgo por ticket?
--
-- EL HECHO A EXPLICAR (C7, ventana 202207-202505)
--   RD por tamanio de ticket IBK, monotona en las dos personerias:
--     ticket grande   PJJ  7.82%   PNN 10.28%
--     ticket medio    PJJ  9.03%   PNN 11.51%
--     ticket chico    PJJ 13.27%   PNN 20.99%
--   Casi 2x entre puntas en PNN. No hay escalon en 30k: hay pendiente.
--
-- LA PREGUNTA QUE DECIDE QUE MAS HAY QUE HACER
--   Si ese gradiente YA esta en el pd_raw -> incluir monto_chico alcanza, la calibracion
--   solo ajusta nivel y no hace falta nada mas.
--   Si NO esta -> hay brecha de DISCRIMINACION, no de calibracion: el modelo daria la
--   misma PD a dos grupos que incumplen al doble. Ahi las salidas son otras (segmentar,
--   meter el monto como variable, corregir en estrategia).
--   Excluirlos no arregla ninguno de los dos casos: solo evita medir el problema.
--
-- EL TEST DECISIVO ES EL BLOQUE 2
--   Dentro de una MISMA banda de pd_raw, el ticket chico sigue incumpliendo mas?
--     si la RD es plana entre tramos dentro de cada decil -> el modelo LO CAPTURA
--     si el ticket chico sigue arriba dentro del mismo decil -> NO lo captura
--
-- saldo_m0_ibk se reconstruye igual que en C7 (RCC filtrado a '00002', tipo_credito 8-10,
-- mismos tags). Desfase de produccion: p_codmes = codmes_alta - 1.
--
-- Poblacion: flg_ibk=1, TOP4, sin impulsa ni reactiva_puro, 202207-202505.
-- SIN filtrar por flg_monto ni por flg_calib: se mira la poblacion completa, que es
-- justamente la que produccion puntua.
--
-- ~45 filas. READ-ONLY.
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
                  THEN saldo ELSE 0 END) AS s0_ibk
  FROM rcc_ibk GROUP BY 1,2,3
),
sc AS (
  SELECT tip_doc, key_value, p_codmes, max(probabilidad) AS pd_raw
  FROM e_perm_aws.scr_admbankbpe_rsk
  WHERE p_codmes BETWEEN '202206' AND '202504'
  GROUP BY 1,2,3
),
b AS (
  SELECT c.personeria,
         cast(c.target_12m AS double) AS y,
         cast(sc.pd_raw AS double)    AS pd_raw,
         coalesce(i.s0_ibk, 0)        AS s0_ibk,
         CASE WHEN coalesce(i.s0_ibk,0) <  10000 THEN '1 · < 10k'
              WHEN coalesce(i.s0_ibk,0) <  30000 THEN '2 · 10-30k'
              WHEN coalesce(i.s0_ibk,0) < 100000 THEN '3 · 30-100k'
              ELSE                                    '4 · >= 100k' END AS tramo
  FROM disc_model_owner.bnbpe_ibk_calib_src c
  LEFT JOIN s0 i
    ON i.codmes = c.codmes AND i.tip_doc = c.tip_doc AND i.key_value = c.key_value
  JOIN sc
    ON sc.tip_doc = c.tip_doc AND sc.key_value = c.key_value
   AND c.codmes = cast(date_format(date_parse(cast(sc.p_codmes AS varchar),'%Y%m')
                                   + interval '1' month, '%Y%m') AS varchar)
  WHERE c.flg_ibk = 1 AND c.top4_entidad = 'TOP4'
    AND coalesce(c.flg_impulsa,0) = 0 AND coalesce(c.flg_reactiva_puro,0) = 0
    AND cast(c.codmes AS int) BETWEEN 202207 AND 202505
),
d AS (
  SELECT *, ntile(5) OVER (PARTITION BY personeria ORDER BY pd_raw) AS q_pd
  FROM b
),
rk AS (
  SELECT *, rank() OVER (PARTITION BY tramo, personeria ORDER BY pd_raw) AS r
  FROM b
)

-- ------------------------------------------------- 1. ¿el pd_raw ordena los tramos?
-- Si el scorecard capta el monto, el pd_raw medio deberia SUBIR al bajar el ticket,
-- siguiendo a la RD.
SELECT '1. ORDENA?' AS bloque, tramo AS detalle, personeria,
       cast(count(*) AS varchar) AS n,
       cast(round(100.0 * avg(y), 2) AS varchar) || ' % RD' AS obs,
       cast(round(100.0 * avg(pd_raw), 2) AS varchar) || ' % pd_raw' AS pred
FROM b GROUP BY tramo, personeria

-- ------------------------------------------------- 2. EL TEST DECISIVO
-- Dentro del mismo quintil de pd_raw, el ticket chico sigue incumpliendo mas?
UNION ALL
SELECT '2. DENTRO DEL QUINTIL', 'q' || cast(q_pd AS varchar) || ' · ' || tramo, personeria,
       cast(count(*) AS varchar),
       cast(round(100.0 * avg(y), 2) AS varchar) || ' % RD',
       cast(round(100.0 * avg(pd_raw), 2) AS varchar) || ' % pd_raw'
FROM d GROUP BY q_pd, tramo, personeria
HAVING count(*) >= 30

-- ------------------------------------------------- 3. brecha por quintil
-- Resumen del bloque 2: RD del ticket chico menos RD del ticket grande, dentro del
-- mismo quintil. Si el modelo captura, esto tiende a 0.
UNION ALL
SELECT '3. BRECHA', 'q' || cast(q_pd AS varchar) || ' · chico(<30k) vs grande(>=30k)', personeria,
       cast(count_if(s0_ibk < 30000) AS varchar) || ' vs ' || cast(count_if(s0_ibk >= 30000) AS varchar),
       cast(round(100.0 * (
            sum(CASE WHEN s0_ibk <  30000 THEN y ELSE 0 END) / nullif(count_if(s0_ibk <  30000), 0)
          - sum(CASE WHEN s0_ibk >= 30000 THEN y ELSE 0 END) / nullif(count_if(s0_ibk >= 30000), 0)
       ), 2) AS varchar) || ' pp',
       'DEBE tender a 0 si el modelo capta'
FROM d GROUP BY q_pd, personeria

-- ------------------------------------------------- 4. discriminacion DENTRO de cada tramo
-- AUC por rangos. Si el scorecard no ordena adentro del tramo chico, el problema no se
-- arregla con nivel: hay que segmentar.
-- (rank() empata en los ties, asi que el AUC queda levemente sesgado; sirve de diagnostico.)
UNION ALL
SELECT '4. AUC POR TRAMO', tramo, personeria,
       cast(count(*) AS varchar),
       cast(round((sum(CASE WHEN y = 1 THEN r END)
                   - count_if(y = 1) * (count_if(y = 1) + 1) / 2.0)
                  / nullif(count_if(y = 1) * count_if(y = 0), 0), 4) AS varchar) || ' AUC',
       'Gini ' || cast(round(2 * (sum(CASE WHEN y = 1 THEN r END)
                   - count_if(y = 1) * (count_if(y = 1) + 1) / 2.0)
                  / nullif(count_if(y = 1) * count_if(y = 0), 0) - 1, 4) AS varchar)
FROM rk GROUP BY tramo, personeria
HAVING count_if(y = 1) >= 15

ORDER BY 1, 2, 3
