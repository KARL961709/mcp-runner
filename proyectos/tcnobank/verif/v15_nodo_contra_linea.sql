-- ============================================================================
-- V15. EL NODO SOBREVIVE AL CONTROLAR POR LINEA, Y CUANTO PESA CADA CELDA
--   scan: __T___cal sobre flg_calib = 1 y flg_clean = 1, las 5 entidades
--   ancla: v14 dio ratio_obs_pred 0.373 contra 0.974 por ctrl_solo_linea con cobertura
--          total, y v13 mostro que el nodo aporta sobre el score dentro de IBK. Si al
--          fijar la linea el nodo deja de separar, es la misma variable vista en una
--          sola entidad y calibrar por linea cumple el pedido en sustancia. Si separa
--          igual, son dos cosas y la celda tiene que combinar las dos
--   la salida es directamente el diseno de celdas: n y ratio de cada una
-- ============================================================================
SELECT CASE WHEN entidad = '00002' THEN '1.IBK' ELSE '2.resto' END                      AS ambito,
       coalesce(nodo_final, 'SIN_DATO')                                                 AS nodo,
       CASE WHEN ctrl_solo_linea = 1 THEN '1.solo linea'
            ELSE                          '2.con saldo' END                             AS linea,
       count(*)                                                                         AS n,
       sum(target_12m)                                                                  AS n_malo,
       round(100.0 * avg(CAST(target_12m AS DOUBLE)), 4)                                AS rd_12m,
       round(100.0 * avg(pd_raw), 4)                                                    AS pd_raw_media,
       round(avg(CAST(target_12m AS DOUBLE)) / nullif(avg(pd_raw), 0), 4)               AS ratio_obs_pred
FROM disc_model_owner.ds_adm_vcnbank_tc_cal
WHERE flg_calib = 1 AND flg_clean = 1
GROUP BY GROUPING SETS (
    (CASE WHEN entidad = '00002' THEN '1.IBK' ELSE '2.resto' END,
     coalesce(nodo_final, 'SIN_DATO'),
     CASE WHEN ctrl_solo_linea = 1 THEN '1.solo linea' ELSE '2.con saldo' END),
    (CASE WHEN entidad = '00002' THEN '1.IBK' ELSE '2.resto' END,
     coalesce(nodo_final, 'SIN_DATO')),
    (CASE WHEN entidad = '00002' THEN '1.IBK' ELSE '2.resto' END,
     CASE WHEN ctrl_solo_linea = 1 THEN '1.solo linea' ELSE '2.con saldo' END))
ORDER BY ambito, nodo, linea
LIMIT 40
