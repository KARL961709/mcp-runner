-- 1t7_b_tag.sql | TRAMO 1T7  codmes 202506-202506 (1 mes) | -> disc_model_owner.ds_adm_bpe_bankbn_tmp_tag
-- Tramificado desde 10b_tag.sql. Unico cambio respecto del original: los literales de
-- ventana (y el destino por tramo). Logica de negocio intacta.
--
--   escribe : codmes 202506..202506
--   lee     : RCC 202506..202506 (solo el tramo)
--   particion: p_codmes 202504..202508 (+-2m, misma convencion del original)
--   las tmp_* son DESCARTABLES por tramo (drop+create dentro del tramo).
--   Cada tramo escribe su propia tabla po_tN; 1z_b_po_union consolida las 7.
--   tmp_tag NO lleva historia: sus consumidores (10d semi-join, 10f driver) la usan
--   como conjunto de claves/meses de alta, no como serie historica.
-- ---------------------------------------------------------------------------
-- NOTAS DEL ORIGINAL (10b_tag.sql):
-- 10b_tag.sql | etapa 1/5 de la PO | RCC 202206-202506 -> disc_model_owner.ds_adm_bpe_bankbn_tmp_tag
-- Origen: CTE morigbk_tag de 10_po_altas.sql (partido en etapas materializadas: Trino INLINEA los CTE,
-- no los materializa, y morigbk_tag se referenciaba 2 veces sobre 37 meses de RCC).
--
--  1. UN SOLO STATEMENT (CTAS). Athena no soporta CREATE OR REPLACE: correr antes 1t7_a_drop_tag.sql.
--  2. A12 ventana: codmes 202206..202506 (37 meses). A6 fuente: e_perm_aws cubre >=201901.
--  3. Poda: WHERE p_codmes (columna de particion, ventana ampliada +-2m) + WHERE codmes (logica, exacto).
--  4. Los dos consumidores (10d semi-join por tip_doc/key_value, 10f driver por
--     codmes/tip_doc/key_value/cod_instit_financiera) aplicaban ambos el mismo
--     `tag IN (...) AND ent_honrada=0`. Ese filtro se baja aqui y la tabla queda al grano de 4 claves
--     en vez de persistir el RCC entero. Mismo conjunto de filas que el CTE original en ambos casos.
--  5. flg_saldo_pos sustituye al `saldo>0` que el driver de 10f aplicaba fila a fila: max(...)=1 <=>
--     habia al menos una fila con saldo>0 en el grupo, que es lo que el GROUP BY 1,2,3,4 original dejaba.
--     El consumidor 10d NO lo usa (el original tampoco filtraba por saldo en el semi-join).
--  6. Proyeccion explicita: condicion / cod_clasificacion_deudor no los lee ningun consumidor de esta etapa.
CREATE TABLE disc_model_owner.ds_adm_bpe_bankbn_tmp_tag AS
SELECT codmes, tip_doc, key_value, cod_instit_financiera,
       max(CASE WHEN saldo > 0 THEN 1 ELSE 0 END) AS flg_saldo_pos
FROM (
    SELECT a.codmes, a.tip_doc, a.key_value, a.cod_instit_financiera, a.saldo,
        CASE
            WHEN substr(a.cod_cuenta_rcc,1,2)='14' AND substr(a.cod_cuenta_rcc,4,1) IN ('1','3','4','5','6') THEN
                CASE WHEN cast(a.tipo_credito AS int) BETWEEN 8 AND 10 THEN
                        CASE
                            WHEN (cast(a.tipo_credito AS int) BETWEEN 8 AND 10) AND substr(a.cod_cuenta_rcc,7,2)='05' THEN 'DESCUENTOS'
                            WHEN (cast(a.tipo_credito AS int) BETWEEN 8 AND 10) AND substr(a.cod_cuenta_rcc,7,2)='10' THEN 'FACTORING'
                            WHEN (cast(a.tipo_credito AS int) BETWEEN 8 AND 10) AND substr(a.cod_cuenta_rcc,7,2)='04' THEN 'SOBREGIRO'
                            WHEN (cast(a.tipo_credito AS int) BETWEEN 8 AND 10) AND substr(a.cod_cuenta_rcc,7,2)='01' THEN 'AVANCE CC'
                            ELSE 'RESTO DD NEGOCIO'
                        END
                    ELSE 'RESTO DD'
                END
            WHEN substr(a.cod_cuenta_rcc,1,2)='72' AND substr(a.cod_cuenta_rcc,4,1)='5' THEN
                CASE WHEN cast(a.tipo_credito AS int) BETWEEN 8 AND 10 THEN
                        CASE
                            WHEN (cast(a.tipo_credito AS int) BETWEEN 8 AND 10) AND substr(a.cod_cuenta_rcc,5,2)='02' THEN 'LC DESCUENTO'
                            WHEN (cast(a.tipo_credito AS int) BETWEEN 8 AND 10) AND substr(a.cod_cuenta_rcc,5,2) IN ('03','06','08','09') THEN 'LC NO UTILIZADA'
                            ELSE 'RESTO LC NEGOCIO'
                        END
                    ELSE 'RESTO LC'
                END
        ELSE 'OTROS' END AS tag,
        CASE WHEN a.cod_instit_financiera IN ('00469','00470','00472','00477','00478','00497','00498','00499','00500','00508',
                    '00509','00510','00512','00513','00514','00516','00517','00518','00519','00580','00581','00582','00583',
                    '00587','00588','00589','00592','00593','00594','00596','00598','00599','00600') THEN 1 ELSE 0 END AS ent_honrada
    FROM (
        SELECT codmes, tip_doc, key_value, tipo_credito, cod_cuenta_rcc, cod_instit_financiera, saldo
        FROM e_perm_aws.t_fact_report_rcc_rsk
        WHERE p_codmes BETWEEN '202504' AND '202508'
          AND codmes   BETWEEN '202506' AND '202506'
    ) a
) t
WHERE tag IN ('RESTO DD NEGOCIO','DESCUENTOS','FACTORING','LC NO UTILIZADA','LC DESCUENTO')
  AND ent_honrada = 0
GROUP BY 1,2,3,4
