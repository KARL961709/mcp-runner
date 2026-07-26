-- 1t5_d_rcc.sql | TRAMO 1T5  codmes 202406-202411 (6 meses) | -> disc_model_owner.ds_adm_bpe_bankbn_tmp_rcc
-- Tramificado desde 10d_rcc.sql. Unico cambio respecto del original: los literales de
-- ventana (y el destino por tramo). Logica de negocio intacta.
--
--   escribe : codmes 202406..202411
--   lee     : RCC 202305..202411 (13m de historia antes de 202406)
--   particion: p_codmes 202303..202501 (+-2m, misma convencion del original)
--   las tmp_* son DESCARTABLES por tramo (drop+create dentro del tramo).
--   Cada tramo escribe su propia tabla po_tN; 1z_b_po_union consolida las 7.
--   La historia NO se recorta al tramo: 10f pide [m0-13, m0] y deuda_*_u12m_v2
--   llega a m0-13. Acotar a 202406..202411 vaciaria los meses de arranque.
--   El semi-join contra tmp_tag deja solo las claves que dan de alta en el tramo.
-- ---------------------------------------------------------------------------
-- NOTAS DEL ORIGINAL (10d_rcc.sql):
-- 10d_rcc.sql | etapa 2/5 de la PO | historia RCC 202105-202506 -> disc_model_owner.ds_adm_bpe_bankbn_tmp_rcc
-- Origen: CTE morigbk_rcc + CTE interno data_rcc de 10_po_altas.sql.
--
--  1. UN SOLO STATEMENT (CTAS). Correr antes 1t5_c_drop_rcc.sql. Requiere ds_adm_bpe_bankbn_tmp_tag (10b).
--  2. Historia a m0-13 (no m0-12): la consumen deuda_*_u12m_v2 ([m0-13, m0-2]) en 10f. Replica notebook_code.py L109.
--     Las altas (saldo_mo_u1m..u1a) solo usan m1..m12, no se ven afectadas.
--  3. A6 fuente: e_perm_aws cubre >=201901 y 202105 >= 201901 => NO se requiere UNION con d_perm_aws.
--     El UNION disjunto solo haria falta para la serie macro (~201505). Build aparte.
--  4. Se materializa ya AGREGADO al grano (codmes, tip_doc, key_value, tipo_credito, cod_instit_financiera):
--     es el unico grano que consume 10f y colapsa el detalle cuenta a cuenta antes de persistir.
--  5. El SELECT DISTINCT del original se conserva DENTRO del subquery: precede a los sum() y
--     colapsa filas repetidas del RCC. Quitarlo cambiaria los saldos.
--  6. El semi-join contra tmp_tag es subconsulta con GROUP BY 1,2 => no produce fan. Sin cambio.
CREATE TABLE disc_model_owner.ds_adm_bpe_bankbn_tmp_rcc AS
SELECT codmes, tip_doc, key_value, tipo_credito, cod_instit_financiera,
    max(CASE WHEN cast(tipo_credito AS int) BETWEEN 1 AND 10 AND tag IN ('RESTO DD','DESCUENTOS','FACTORING','REFINANCIADOS','LC NO UTILIZADA','LC DESCUENTO') THEN condicion ELSE null END) AS dm,
    sum(CASE WHEN cast(tipo_credito AS int) BETWEEN 1 AND 10 AND tag IN ('RESTO DD','DESCUENTOS','FACTORING','REFINANCIADOS','LC NO UTILIZADA','LC DESCUENTO') THEN saldo ELSE 0 END) AS saldo_mo,
    sum(CASE WHEN cast(tipo_credito AS int) BETWEEN 8 AND 10 AND tag IN ('RESTO DD','DESCUENTOS','FACTORING','REFINANCIADOS','LC NO UTILIZADA','LC DESCUENTO') AND ent_honrada=0 THEN saldo ELSE 0 END) AS saldo_m0_entidad,
    sum(CASE WHEN garantia='gar_p'        THEN saldo ELSE null END) AS saldo_gar_p,
    sum(CASE WHEN garantia='gar_np'       THEN saldo ELSE null END) AS saldo_gar_np,
    sum(CASE WHEN garantia='Sin Garantia' THEN saldo ELSE null END) AS saldo_sg,
    sum(CASE WHEN flg_tipo_credito='ins' AND regexp_like(cod_cuenta_rcc, '^14.[13456]|^81.(302|925)') THEN saldo ELSE 0 END) AS deuda_ins,
    sum(CASE WHEN flg_tipo_credito='neg' AND regexp_like(cod_cuenta_rcc, '^14.[13456]|^81.(302|925)') THEN saldo ELSE 0 END) AS deuda_neg,
    sum(CASE WHEN flg_tipo_credito='con' AND regexp_like(cod_cuenta_rcc, '^14.[13456]|^81.(302|925)') THEN saldo ELSE 0 END) AS deuda_con
FROM (
    SELECT DISTINCT a.codmes, a.tip_doc, a.key_value, a.condicion, a.tipo_credito, a.cod_cuenta_rcc,
           a.cod_instit_financiera, a.cod_clasificacion_deudor, a.saldo,
        CASE
            WHEN substr(a.cod_cuenta_rcc,1,2)='14' AND substr(a.cod_cuenta_rcc,4,1) IN ('1','3','4','5','6') THEN
                CASE
                    WHEN (cast(a.tipo_credito AS int) BETWEEN 1 AND 10) AND substr(a.cod_cuenta_rcc,7,2)='05' THEN 'DESCUENTOS'
                    WHEN (cast(a.tipo_credito AS int) BETWEEN 1 AND 10) AND substr(a.cod_cuenta_rcc,7,2)='10' THEN 'FACTORING'
                    WHEN (cast(a.tipo_credito AS int) BETWEEN 1 AND 10) AND substr(a.cod_cuenta_rcc,7,2)='04' THEN 'SOBREGIRO'
                    WHEN (cast(a.tipo_credito AS int) BETWEEN 1 AND 10) AND substr(a.cod_cuenta_rcc,7,2)='01' THEN 'AVANCE CC'
                    WHEN (cast(a.tipo_credito AS int) BETWEEN 1 AND 10) AND substr(a.cod_cuenta_rcc,4,1)='4' THEN 'REFINANCIADOS'
                    ELSE 'RESTO DD'
                END
            WHEN substr(a.cod_cuenta_rcc,1,2)='72' AND substr(a.cod_cuenta_rcc,4,1)='5' THEN
                CASE
                    WHEN (cast(a.tipo_credito AS int) BETWEEN 1 AND 10) AND substr(a.cod_cuenta_rcc,5,2)='02' THEN 'LC DESCUENTO'
                    WHEN (cast(a.tipo_credito AS int) BETWEEN 1 AND 10) AND substr(a.cod_cuenta_rcc,5,2) IN ('03','06','08','09') THEN 'LC NO UTILIZADA'
                    ELSE 'RESTO LC'
                END
        ELSE 'OTROS' END AS tag,
        CASE WHEN a.cod_instit_financiera IN ('00469','00470','00472','00477','00478','00497','00498','00499','00500','00508',
                    '00509','00510','00512','00513','00514','00516','00517','00518','00519','00580','00581','00582','00583',
                    '00587','00588','00589','00592','00593','00594','00596','00598','00599','00600') THEN 1 ELSE 0 END AS ent_honrada,
        CASE WHEN regexp_like(a.cod_cuenta_rcc, '^84.40[12345]') THEN 'gar_p'
             WHEN regexp_like(a.cod_cuenta_rcc, '^84.4(09|10)') THEN 'gar_np'
             ELSE 'Sin Garantia' END AS garantia,
        CASE
            WHEN a.tipo_credito IN ('01','02','03','04','05') THEN 'ins'
            WHEN a.tipo_credito IN ('06','07','08','09','10') THEN 'neg'
            WHEN a.tipo_credito IN ('11','12','13')           THEN 'con'
            ELSE 'otro'
        END AS flg_tipo_credito
    FROM (
        SELECT codmes, tip_doc, key_value, condicion, tipo_credito, cod_cuenta_rcc, cod_instit_financiera,
               cod_clasificacion_deudor, saldo
        FROM e_perm_aws.t_fact_report_rcc_rsk
        WHERE p_codmes BETWEEN '202303' AND '202501'
          AND codmes   BETWEEN '202305' AND '202411'
    ) a
    INNER JOIN (
        SELECT tip_doc, key_value
        FROM disc_model_owner.ds_adm_bpe_bankbn_tmp_tag
        GROUP BY 1,2
    ) b
    ON a.tip_doc = b.tip_doc AND a.key_value = b.key_value
) r
GROUP BY 1,2,3,4,5
