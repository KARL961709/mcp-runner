-- ============================================================================
-- D10. QUE ENTIDAD PRODUCE EL PICO DE MALO EN EL ORIGEN DE 202406 A 202408
--   scan: disc_model_owner.ds_adm_vcnbank_tc_cal, tabla previa a la reconstruccion
--   ancla: d8 muestra que pct_malo_ori se triplica tres meses y vuelve. Una compra de
--          cartera se concentra en una entidad y un trimestre. Un fenomeno real no
-- ============================================================================
WITH b AS (
    SELECT codmes_mrm, tip_doc, id_value, entidad,
           max(ctrl_malo_ori_m0) AS malo_ori,
           max(target_12m)       AS target_12m
    FROM disc_model_owner.ds_adm_vcnbank_tc_cal
    WHERE flg_calib = 1 AND flg_clean = 1
    GROUP BY codmes_mrm, tip_doc, id_value, entidad
)
SELECT b.entidad,
       e.nombre_instit_financiera,
       CASE WHEN b.codmes_mrm BETWEEN '202406' AND '202408' THEN '1.pico 202406 a 202408'
            ELSE                                                 '2.resto de la ventana' END AS ventana,
       count(*)                                                                         AS n,
       sum(b.malo_ori)                                                                  AS n_malo_ori,
       round(100.0 * avg(CAST(b.malo_ori AS DOUBLE)), 4)                                AS pct_malo_ori,
       round(100.0 * avg(CASE WHEN b.malo_ori = 1
                              THEN CAST(b.target_12m AS DOUBLE) END), 4)                AS rd_malo_ori
FROM b
LEFT JOIN e_perm_aws.t_dim_inst_fin_rsk e
       ON ltrim(rtrim(e.cod_instit_financiera)) = b.entidad
GROUP BY b.entidad, e.nombre_instit_financiera,
         CASE WHEN b.codmes_mrm BETWEEN '202406' AND '202408' THEN '1.pico 202406 a 202408'
              ELSE                                                 '2.resto de la ventana' END
ORDER BY n_malo_ori DESC
LIMIT 40
