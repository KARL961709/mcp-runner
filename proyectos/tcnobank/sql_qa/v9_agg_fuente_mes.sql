-- v9_agg_fuente_mes.sql | G9. La capa agregada tiene que cubrir 201701 a 202606 sin hueco ni solape. Un mes faltante
-- se propaga como missing y falsea el target, y un mes duplicado infla los saldos. Se cuenta por mes, no con min y max,
-- porque min y max sobre particiones declaradas ya produjo una vez un rango que no existia en el dato.
SELECT 'G9'                                                                    AS gate,
       chk, n_viol, n_magnitud,
       CASE WHEN n_viol = 0 THEN 'PASS' ELSE 'FAIL' END                        AS veredicto
FROM (
    SELECT 'meses esperados sin filas en la capa agregada'                     AS chk,
           114 - count(DISTINCT codmes)                                        AS n_viol,
           count(DISTINCT codmes)                                              AS n_magnitud
    FROM disc_model_owner.ds_adm_tcnb_05_rcc_agg
    WHERE codmes BETWEEN '201701' AND '202606'
    UNION ALL
    SELECT 'llaves duplicadas dentro de un mes en la capa agregada',
           count(*),
           (SELECT count(*) FROM disc_model_owner.ds_adm_tcnb_05_rcc_agg)
    FROM (SELECT codmes, tip_doc, key_value, entidad
          FROM disc_model_owner.ds_adm_tcnb_05_rcc_agg GROUP BY 1,2,3,4 HAVING count(*) > 1) d
) y
