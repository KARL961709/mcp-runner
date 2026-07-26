-- 1t5_i_po.sql | TRAMO 5 | -> disc_model_owner.ds_adm_bpe_bankbn_po_t5 (tabla por tramo: idempotente, se re-corre sin duplicar)
-- Tramificado desde 10i_po.sql. Unico cambio respecto del original: los literales de
-- ventana (y el destino por tramo). Logica de negocio intacta.
--
--   escribe : codmes 202406..202411
--   lee     : tmp_bank + tmp_altas (202406..202411) + e_perm_aws.t_dim_inst_fin_rsk
--   las tmp_* son DESCARTABLES por tramo (drop+create dentro del tramo).
--   Cada tramo escribe su propia tabla po_tN; 1z_b_po_union consolida las 7.
--   INSERT INTO: la tabla ya existe desde 1t1_i. NO dropear, acumula.
--   Athena matchea por POSICION, no por nombre. El SELECT es byte a byte el mismo
--   que el de 1t1_i y las tmp_* se recrean con el mismo CTAS en cada tramo, asi que
--   la proyeccion sale con identico orden y tipos de columna.
-- ---------------------------------------------------------------------------
-- NOTAS DEL ORIGINAL (10i_po.sql):
-- 10i_po.sql | etapa 5/5 de la PO | entidad de alta + dedup -> disc_model_owner.ds_adm_bpe_bankbn_po
-- Origen: CTE base_altas_cliente + SELECT final de 10_po_altas.sql.
--
--  1. UN SOLO STATEMENT (INSERT INTO). NO dropear ds_adm_bpe_bankbn_po aqui: acumula.
--     Requiere tmp_altas (10f) y tmp_bank (10h).
--  2. MONTH-AWARE (obligatorio): a.codmes = b.codmes. Sin esto un cliente con altas en 2 meses se
--     duplica y hereda la entidad del otro mes (cross-join real).
--  3. RANK(): PARTITION BY a.codmes, a.tip_doc, a.key_value. Sin codmes quedaria 1 sola fila por
--     cliente en toda la ventana (se perderian ~36 de 37 meses).
--  4. Q6: COALESCE(c.nombre_instit_financiera,'SIN NOMBRE') en el NOT IN. Sin COALESCE, nombre NULL =>
--     NULL NOT IN (...) => NULL => drop silencioso. Al sobrevivir esas filas, el ORDER BY del RANK usa
--     COALESCE(c.cod_instit_financiera, b.cod_instit_financiera) para no empatar en NULL.
--  5. Control: falla_entidad_alta (sin alta emparejada en el mes), falla_nombre_inst (entidad no resuelta en el dim).
--  6. Grano y columnas: 1 fila por (codmes, tip_doc, key_value). saldo_m0..m12 y max_saldo = SISTEMA
--     (vienen de tmp_bank). Sufijo _ent = entidad de alta (A2.2). codmes_score = codmes-1 (A4).
--  7. Fuera de alcance de este archivo (van en 20_target_filtros.sql): A7 rezago m-2, Q1 target_12m,
--     Q5 ventanas 12um, filtros del signed.yaml.
CREATE TABLE disc_model_owner.ds_adm_bpe_bankbn_po_t5 AS
WITH base_altas_cliente AS (
    SELECT
        a.*,
        b.cod_instit_financiera,
        c.nombre_instit_financiera,
        b.marca_entidad,
        b.tipo_credito,
        b.altas, b.alta12, b.alta6, b.alta2,
        b.flg_garantia, b.gar_p, b.gar_np, b.filtro_saldo,
        b.dm_m0, b.dm_m1, b.dm_m2,
        b.max_saldo AS max_saldo_ent,
        b.saldo_m0  AS saldo_m0_ent,
        b.deuda_ins_u12m, b.deuda_neg_u12m, b.deuda_con_u12m,
        b.deuda_ins_u12m_v2, b.deuda_neg_u12m_v2, b.deuda_con_u12m_v2,
        CASE WHEN b.cod_instit_financiera   IS NULL THEN 1 ELSE 0 END AS falla_entidad_alta,
        CASE WHEN c.nombre_instit_financiera IS NULL THEN 1 ELSE 0 END AS falla_nombre_inst,
        ROW_NUMBER() OVER (PARTITION BY a.codmes, a.tip_doc, a.key_value
                     ORDER BY COALESCE(c.cod_instit_financiera, b.cod_instit_financiera) ASC) AS rank
    FROM disc_model_owner.ds_adm_bpe_bankbn_tmp_bank a
    LEFT JOIN (SELECT * FROM disc_model_owner.ds_adm_bpe_bankbn_tmp_altas WHERE alta2 = 1) b
      ON a.codmes = b.codmes AND a.key_value = b.key_value AND a.tip_doc = b.tip_doc
    LEFT JOIN (SELECT cod_instit_financiera, max(nombre_instit_financiera) AS nombre_instit_financiera
               FROM e_perm_aws.t_dim_inst_fin_rsk GROUP BY 1) c
      ON c.cod_instit_financiera = b.cod_instit_financiera
    WHERE a.max_saldo > 0
      AND COALESCE(c.nombre_instit_financiera,'SIN NOMBRE') NOT IN (
            'BANCO AGROPECUARIO','BANCO DE LA NACION',
            'CAJA RURAL DE AHORRO Y CREDITO SIPAN S A','LEASING TOTAL S A','VALOR NO ENVIADO POR IBK')
      AND UPPER(COALESCE(c.nombre_instit_financiera,'SIN NOMBRE')) NOT LIKE 'BBVA CONSUMER%'
)
SELECT *,
    codmes AS p_codmes,
    date_format(date_parse(codmes,'%Y%m') - interval '1' month,'%Y%m') AS codmes_score
FROM base_altas_cliente
WHERE rank = 1
