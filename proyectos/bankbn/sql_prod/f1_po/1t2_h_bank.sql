-- 1t2_h_bank.sql | TRAMO 1T2  codmes 202212-202305 (6 meses) | -> disc_model_owner.ds_adm_bpe_bankbn_tmp_bank
-- Tramificado desde 10h_bank.sql. Unico cambio respecto del original: los literales de
-- ventana (y el destino por tramo). Logica de negocio intacta.
--
--   escribe : codmes 202212..202305
--   lee     : RCC 202111..202305 (13m de historia antes de 202212)
--   particion: p_codmes 202109..202307 (+-2m, misma convencion del original)
--   las tmp_* son DESCARTABLES por tramo (drop+create dentro del tramo).
--   Cada tramo escribe su propia tabla po_tN; 1z_b_po_union consolida las 7.
--   Misma razon que 10d: el pivot saldo_m0..m12 pide [m0-13, m0]. Lado SISTEMA
--   (sin filtro de entidad ni tag), driver = tmp_altas de ESTE tramo.
-- ---------------------------------------------------------------------------
-- NOTAS DEL ORIGINAL (10h_bank.sql):
-- 10h_bank.sql | etapa 4/5 de la PO | saldo SISTEMA de los clientes con alta -> disc_model_owner.ds_adm_bpe_bankbn_tmp_bank
-- Origen: CTE morigbk_rcc_bank + CTE morigbk_saldo_hist_bank (data_rcc_bank / info_consolid_bank) de 10_po_altas.sql.
--
--  1. UN SOLO STATEMENT (CTAS). Correr antes 1t2_g_drop_bank.sql. Requiere tmp_altas (10f).
--  2. Lado SISTEMA: aqui NO se filtra por entidad ni por tag. saldo_m0..m12 y max_saldo son de TODAS
--     las entidades, asi los consume 20_target_filtros en monto_endeud.
--  3. tmp_altas se lee dos veces (semi-join de la historia y driver del pivot), pero ya es una tabla
--     materializada y pequena: la lectura es barata, no una recomputacion del arbol de 10f.
--  4. MONTH-AWARE (obligatorio): b.codmes BETWEEN [a.codmes-13m] AND a.codmes. Los pivots ya son
--     explicitos por mes, el bound es por costo.
--  5. El DISTINCT del original se conserva antes del sum(). Se proyectan solo las columnas base:
--     tag / ent_honrada / garantia / flg_tipo_credito eran funciones deterministas de esas columnas
--     y ningun consumidor de este lado las lee, asi que no alteran el conjunto que devuelve el DISTINCT.
CREATE TABLE disc_model_owner.ds_adm_bpe_bankbn_tmp_bank AS
WITH data_rcc_bank AS (
    SELECT codmes, tip_doc, key_value,
        sum(CASE WHEN cast(tipo_credito AS int) BETWEEN 1 AND 10 THEN saldo ELSE 0 END) AS saldo_mo
    FROM (
        SELECT DISTINCT a.codmes, a.tip_doc, a.key_value, a.condicion, a.tipo_credito, a.cod_cuenta_rcc,
               a.cod_instit_financiera, a.cod_clasificacion_deudor, a.saldo
        FROM (
            SELECT codmes, tip_doc, key_value, condicion, tipo_credito, cod_cuenta_rcc, cod_instit_financiera,
                   cod_clasificacion_deudor, saldo
            FROM e_perm_aws.t_fact_report_rcc_rsk
            WHERE p_codmes BETWEEN '202109' AND '202307'
              AND codmes   BETWEEN '202111' AND '202305'
        ) a
        INNER JOIN (
            SELECT tip_doc, key_value
            FROM disc_model_owner.ds_adm_bpe_bankbn_tmp_altas
            WHERE alta2 = 1
            GROUP BY 1,2
        ) b
        ON a.tip_doc = b.tip_doc AND a.key_value = b.key_value
    ) r
    GROUP BY 1,2,3
),
info_consolid_bank AS (
    SELECT a.codmes, a.tip_doc, a.key_value,
        sum(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '0' month,'%Y%m') AS int) THEN saldo_mo ELSE 0 END) AS saldo_m0,
        sum(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '1' month,'%Y%m') AS int) THEN saldo_mo ELSE 0 END) AS saldo_m1,
        sum(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '2' month,'%Y%m') AS int) THEN saldo_mo ELSE 0 END) AS saldo_m2,
        sum(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '3' month,'%Y%m') AS int) THEN saldo_mo ELSE 0 END) AS saldo_m3,
        sum(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '4' month,'%Y%m') AS int) THEN saldo_mo ELSE 0 END) AS saldo_m4,
        sum(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '5' month,'%Y%m') AS int) THEN saldo_mo ELSE 0 END) AS saldo_m5,
        sum(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '6' month,'%Y%m') AS int) THEN saldo_mo ELSE 0 END) AS saldo_m6,
        sum(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '7' month,'%Y%m') AS int) THEN saldo_mo ELSE 0 END) AS saldo_m7,
        sum(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '8' month,'%Y%m') AS int) THEN saldo_mo ELSE 0 END) AS saldo_m8,
        sum(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '9' month,'%Y%m') AS int) THEN saldo_mo ELSE 0 END) AS saldo_m9,
        sum(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '10' month,'%Y%m') AS int) THEN saldo_mo ELSE 0 END) AS saldo_m10,
        sum(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '11' month,'%Y%m') AS int) THEN saldo_mo ELSE 0 END) AS saldo_m11,
        sum(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '12' month,'%Y%m') AS int) THEN saldo_mo ELSE 0 END) AS saldo_m12
    FROM (
        SELECT codmes, tip_doc, key_value
        FROM disc_model_owner.ds_adm_bpe_bankbn_tmp_altas
        WHERE alta2 = 1
        GROUP BY 1,2,3
    ) a
    LEFT JOIN data_rcc_bank b
      ON a.key_value = b.key_value
     AND a.tip_doc   = b.tip_doc
     AND b.codmes BETWEEN date_format(date_parse(a.codmes,'%Y%m') - interval '13' month,'%Y%m') AND a.codmes
    GROUP BY a.codmes, a.tip_doc, a.key_value
)
SELECT a.*,
    greatest(saldo_m1,saldo_m2,saldo_m3,saldo_m4,saldo_m5,saldo_m6,saldo_m7,saldo_m8,saldo_m9,saldo_m10,saldo_m11,saldo_m12) AS max_saldo
FROM info_consolid_bank a
