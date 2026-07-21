-- =====================================================================================
-- H1 | ¿QUE DEFINICION DE ALTA usa la tabla madre, y coincide con nuestra derivada?
--
-- CONTEXTO
--   01.AltasMonitoreoV4.sql (enviado_2) construye las altas desde RCC crudo y clasifica
--   por meses consecutivos SIN saldo previo:
--       A-12 (12 meses en cero) ... A-02 (2 meses) ... A-01 ... A-00 (saldo continuo)
--   y define tres marcas:
--       alta12 = A-12          alta6 = A-06..A-12          alta2 = A-02..A-12
--
--   Nuestro q1_altas_src NO ejecuta esa logica: lee la tabla oficial de monitoreo
--   disc_monitorian.t_dan_mrm_admbankbpe_altas_rep con el rank=1 ya aplicado.
--   O sea que HEREDAMOS la definicion. Este query averigua cual es.
--
-- BLOQUE 1  columnas de la tabla madre. Si aparece una columna tipo `altas`,
--           `alta2`, `alta6`, `alta12` o similar, la respuesta esta ahi mismo y no
--           hace falta reconstruir nada desde el RCC.
-- BLOQUE 2  conteo por mes: madre (con los filtros de q1) vs nuestra derivada.
--           Deben coincidir EXACTO si q1 es copia fiel. Cualquier diferencia es
--           un filtro no documentado.
-- BLOQUE 3  reparto por entidad, para ver el peso de IBK dentro del TOP4.
--
-- READ-ONLY.
-- =====================================================================================

-- ---------- 1. columnas de la tabla madre ----------
SELECT '1. COLUMNA madre' AS bloque, column_name AS detalle, data_type AS valor
FROM information_schema.columns
WHERE table_schema = 'disc_monitorian'
  AND table_name   = 't_dan_mrm_admbankbpe_altas_rep'

UNION ALL

-- ---------- 2. conteo madre vs derivada, por mes ----------
SELECT '2. CONTEO ' || cast(codmes AS varchar),
       'madre (filtros de q1)',
       cast(count(*) AS varchar)
FROM disc_monitorian.t_dan_mrm_admbankbpe_altas_rep
WHERE p_codmes BETWEEN '202601' AND '202604'
  AND cast(codmes AS int) BETWEEN 202601 AND 202604
GROUP BY 1,2

UNION ALL

SELECT '2. CONTEO ' || cast(codmes AS varchar),
       'derivada bnbpe_ibk_altas_src',
       cast(count(*) AS varchar)
FROM disc_model_owner.bnbpe_ibk_altas_src
WHERE cast(codmes AS int) BETWEEN 202601 AND 202604
GROUP BY 1,2

UNION ALL

-- ---------- 3. reparto por entidad en la madre ----------
SELECT '3. ENTIDAD',
       cod_instit_financiera || CASE WHEN cod_instit_financiera='00002' THEN ' (IBK)'
                                     WHEN cod_instit_financiera IN ('00001','00004','00006') THEN ' (TOP4)'
                                     ELSE '' END,
       cast(count(*) AS varchar)
FROM disc_monitorian.t_dan_mrm_admbankbpe_altas_rep
WHERE p_codmes BETWEEN '202601' AND '202604'
  AND cast(codmes AS int) BETWEEN 202601 AND 202604
GROUP BY 1,2

ORDER BY 1,2
