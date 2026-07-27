-- qa_03_po_checks.sql | 22 invariantes de ds_adm_bpe_bankbn_po en formato vertical | REGLA UNICA: n_viol tiene que ser 0 en TODAS las filas
WITH a AS (
    SELECT
        CAST(count(1) AS BIGINT) AS n_filas,
        CAST(count(DISTINCT CAST(codmes AS VARCHAR) || '#' || CAST(tip_doc AS VARCHAR) || '#' || CAST(key_value AS VARCHAR)) AS BIGINT) AS n_granos,
        CAST(count(DISTINCT CAST(codmes AS VARCHAR)) AS BIGINT) AS n_meses,
        min(CAST(codmes AS VARCHAR)) AS mes_min,
        max(CAST(codmes AS VARCHAR)) AS mes_max,
        CAST(sum(CASE WHEN rn IS NULL OR rn <> 1 THEN 1 ELSE 0 END) AS BIGINT) AS v_rn,
        CAST(sum(CASE WHEN codmes IS NULL OR tip_doc IS NULL OR key_value IS NULL THEN 1 ELSE 0 END) AS BIGINT) AS v_llave,
        CAST(sum(CASE WHEN max_saldo IS NULL OR CAST(max_saldo AS DOUBLE) <= 0 THEN 1 ELSE 0 END) AS BIGINT) AS v_maxsaldo,
        CAST(sum(CASE WHEN CAST(max_saldo_ent AS DOUBLE) - CAST(max_saldo AS DOUBLE) > 1 THEN 1 ELSE 0 END) AS BIGINT) AS v_entgtsys,
        CAST(sum(CASE WHEN nombre_instit_financiera IS NULL
                        OR nombre_instit_financiera IN ('BANCO AGROPECUARIO','BANCO DE LA NACION','CAJA RURAL DE AHORRO Y CREDITO SIPAN S A','LEASING TOTAL S A','VALOR NO ENVIADO POR IBK')
                        OR UPPER(nombre_instit_financiera) LIKE 'BBVA CONSUMER%'
                      THEN 1 ELSE 0 END) AS BIGINT) AS v_nombre_lit,
        CAST(sum(CASE WHEN UPPER(nombre_instit_financiera) LIKE 'BANCO AGROPECUARIO%'
                        OR UPPER(nombre_instit_financiera) LIKE 'BANCO DE LA NACI%'
                        OR UPPER(nombre_instit_financiera) LIKE 'CAJA RURAL%SIP%'
                        OR UPPER(nombre_instit_financiera) LIKE 'LEASING TOTAL%'
                        OR UPPER(nombre_instit_financiera) LIKE 'VALOR NO ENVIADO%'
                      THEN 1 ELSE 0 END) AS BIGINT) AS v_nombre_pref,
        CAST(sum(CASE WHEN CAST(cod_instit_financiera AS VARCHAR) IN ('00469','00470','00472','00477','00478','00497','00498','00499','00500','00508','00509','00510','00512','00513','00514','00516','00517','00518','00519','00580','00581','00582','00583','00587','00588','00589','00592','00593','00594','00596','00598','00599','00600') THEN 1 ELSE 0 END) AS BIGINT) AS v_honr_exact,
        CAST(sum(CASE WHEN lpad(trim(CAST(cod_instit_financiera AS VARCHAR)), 5, '0') IN ('00469','00470','00472','00477','00478','00497','00498','00499','00500','00508','00509','00510','00512','00513','00514','00516','00517','00518','00519','00580','00581','00582','00583','00587','00588','00589','00592','00593','00594','00596','00598','00599','00600') THEN 1 ELSE 0 END) AS BIGINT) AS v_honr_norm,
        CAST(sum(CASE WHEN COALESCE(falla_entidad_alta, -1) <> 0 OR COALESCE(falla_nombre_inst, -1) <> 0 THEN 1 ELSE 0 END) AS BIGINT) AS v_fallaflags,
        CAST(sum(CASE WHEN altas IS NULL OR altas NOT IN ('A-02','A-03','A-04','A-05','A-06','A-07','A-08','A-09','A-10','A-11','A-12') THEN 1 ELSE 0 END) AS BIGINT) AS v_altas,
        CAST(sum(CASE WHEN COALESCE(alta2, -1) <> 1 THEN 1 ELSE 0 END) AS BIGINT) AS v_alta2,
        CAST(sum(CASE WHEN (COALESCE(alta12, 0) = 1 AND COALESCE(alta6, -1) <> 1) OR (COALESCE(alta6, 0) = 1 AND COALESCE(alta2, -1) <> 1) THEN 1 ELSE 0 END) AS BIGINT) AS v_anida,
        CAST(sum(CASE WHEN CASE WHEN altas = 'A-12' THEN 1 ELSE 0 END <> COALESCE(alta12, -1)
                        OR CASE WHEN altas IN ('A-06','A-07','A-08','A-09','A-10','A-11','A-12') THEN 1 ELSE 0 END <> COALESCE(alta6, -1)
                        OR CASE WHEN altas IN ('A-02','A-03','A-04','A-05','A-06','A-07','A-08','A-09','A-10','A-11','A-12') THEN 1 ELSE 0 END <> COALESCE(alta2, -1)
                      THEN 1 ELSE 0 END) AS BIGINT) AS v_flagtexto,
        CAST(sum(CASE WHEN CAST(tipo_credito AS VARCHAR) IS NULL OR CAST(tipo_credito AS VARCHAR) NOT IN ('08','09','10') THEN 1 ELSE 0 END) AS BIGINT) AS v_tc,
        CAST(sum(CASE WHEN saldo_m0_ent IS NULL OR CAST(saldo_m0_ent AS DOUBLE) <= 0 THEN 1 ELSE 0 END) AS BIGINT) AS v_sm0ent,
        CAST(sum(CASE WHEN CASE WHEN CAST(tipo_credito AS VARCHAR) IN ('08','09') AND CAST(max_saldo_ent AS DOUBLE) <= 1000000 THEN 1
                                WHEN CAST(tipo_credito AS VARCHAR) = '10' AND CAST(max_saldo_ent AS DOUBLE) > 10000 AND CAST(max_saldo_ent AS DOUBLE) <= 1000000 THEN 1
                                ELSE 0 END <> COALESCE(filtro_saldo, -1) THEN 1 ELSE 0 END) AS BIGINT) AS v_filtrosaldo,
        CAST(sum(CASE WHEN CAST(p_codmes AS VARCHAR) IS DISTINCT FROM CAST(codmes AS VARCHAR) THEN 1 ELSE 0 END) AS BIGINT) AS v_pcodmes,
        CAST(sum(CASE WHEN COALESCE(TRY_CAST(substr(CAST(codmes AS VARCHAR), 1, 4) AS INTEGER) * 12 + TRY_CAST(substr(CAST(codmes AS VARCHAR), 5, 2) AS INTEGER)
                             - TRY_CAST(substr(CAST(codmes_score AS VARCHAR), 1, 4) AS INTEGER) * 12 - TRY_CAST(substr(CAST(codmes_score AS VARCHAR), 5, 2) AS INTEGER), -99) <> 1
                      THEN 1 ELSE 0 END) AS BIGINT) AS v_desfase,
        CAST(sum(CASE WHEN (CASE WHEN CAST(cod_instit_financiera AS VARCHAR) = '00002' THEN 1 ELSE 0 END) <> (CASE WHEN marca_entidad = 'IBK' THEN 1 ELSE 0 END) THEN 1 ELSE 0 END) AS BIGINT) AS v_marca,
        CAST(sum(CASE WHEN cod_instit_financiera IS NULL OR trim(CAST(cod_instit_financiera AS VARCHAR)) = '' THEN 1 ELSE 0 END) AS BIGINT) AS v_codnulo,
        CAST(sum(CASE WHEN CAST(cod_instit_financiera AS VARCHAR) = '00002' THEN 1 ELSE 0 END) AS BIGINT) AS o_ibk,
        CAST(sum(CASE WHEN CAST(cod_instit_financiera AS VARCHAR) = '00001' THEN 1 ELSE 0 END) AS BIGINT) AS o_bcp,
        CAST(sum(CASE WHEN CAST(cod_instit_financiera AS VARCHAR) IN ('00001','00002','00004','00006') THEN 1 ELSE 0 END) AS BIGINT) AS o_top4,
        CAST(sum(CASE WHEN altas = 'A-12' THEN 1 ELSE 0 END) AS BIGINT) AS o_a12,
        round(min(CASE WHEN CAST(max_saldo AS DOUBLE) > 0 THEN CAST(max_saldo AS DOUBLE) END), 2) AS o_maxsaldo_min,
        round(approx_percentile(CAST(max_saldo AS DOUBLE), 0.5), 2) AS o_maxsaldo_p50
    FROM disc_model_owner.ds_adm_bpe_bankbn_po
)
SELECT
    t.orden,
    t.chk,
    t.n_viol,
    round(100e0 * t.n_viol / nullif(a.n_filas, 0), 5) AS pct_viol,
    CASE WHEN t.n_viol = 0 THEN 'OK' ELSE 'REVISAR' END AS veredicto,
    a.n_filas,
    a.n_meses,
    a.mes_min,
    a.mes_max,
    a.o_top4,
    a.o_ibk,
    a.o_bcp,
    a.o_a12,
    a.o_maxsaldo_min,
    a.o_maxsaldo_p50
FROM a
CROSS JOIN UNNEST(ARRAY[
    ROW(1, 'P01 grano duplicado codmes tipdoc keyvalue', a.n_filas - a.n_granos),
    ROW(2, 'P02 rn nulo o distinto de 1', a.v_rn),
    ROW(3, 'P03 llave del grano con algun NULL', a.v_llave),
    ROW(4, 'P04 max_saldo sistema nulo o no positivo', a.v_maxsaldo),
    ROW(5, 'P05 max_saldo_ent mayor que max_saldo sistema', a.v_entgtsys),
    ROW(6, 'P06 entidad de alta en lista de exclusion literal o nombre NULL A24', a.v_nombre_lit),
    ROW(7, 'P07 entidad excluida que escapo por acento o espaciado', a.v_nombre_pref),
    ROW(8, 'P08 entidad de alta honrada COVID normalizada', a.v_honr_norm),
    ROW(9, 'P09 honrada ciega al formato norm menos exact', a.v_honr_norm - a.v_honr_exact),
    ROW(10, 'P10 falla_entidad_alta o falla_nombre_inst distintos de 0', a.v_fallaflags),
    ROW(11, 'P11 altas fuera de A-02..A-12 o NULL', a.v_altas),
    ROW(12, 'P12 alta2 distinto de 1', a.v_alta2),
    ROW(13, 'P13 familia de altas no anidada', a.v_anida),
    ROW(14, 'P14 flags alta12 alta6 alta2 no coinciden con el texto altas', a.v_flagtexto),
    ROW(15, 'P15 tipo_credito fuera de 08 09 10', a.v_tc),
    ROW(16, 'P16 saldo_m0_ent nulo o no positivo', a.v_sm0ent),
    ROW(17, 'P17 filtro_saldo recomputado distinto del guardado', a.v_filtrosaldo),
    ROW(18, 'P18 p_codmes distinto de codmes', a.v_pcodmes),
    ROW(19, 'P19 desfase codmes menos codmes_score distinto de 1 mes', a.v_desfase),
    ROW(20, 'P20 marca_entidad IBK no equivale a cod 00002', a.v_marca),
    ROW(21, 'P21 cod_instit_financiera nulo o vacio', a.v_codnulo),
    ROW(22, 'P22 huecos de mes en la cobertura', CAST(date_diff('month', date_parse(a.mes_min, '%Y%m'), date_parse(a.mes_max, '%Y%m')) + 1 - a.n_meses AS BIGINT))
]) AS t (orden, chk, n_viol)
ORDER BY t.orden
