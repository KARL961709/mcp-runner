-- 2t2_f_mad_sunat.sql | padron sunat giros ubigeos restringidos | escribe 201906-202010
CREATE TABLE disc_model_owner.ds_adm_bpe_bankbn_tmp_mad_sunat_t2 AS
WITH uni_mad AS (
    SELECT DISTINCT codmes, tip_doc, key_value
    FROM disc_model_owner.ds_adm_bpe_bankbn_tmp_mad_rcc_t2
),
uni_mad_key AS (
    SELECT DISTINCT tip_doc, key_value
    FROM disc_model_owner.ds_adm_bpe_bankbn_tmp_mad_rcc_t2
),
filtro_sunat AS (
    SELECT DISTINCT a.*
    FROM (
        SELECT a.*,
               ROW_NUMBER() OVER (PARTITION BY codmes, tip_doc, key_value
                            ORDER BY codmes, tip_doc, key_value, cl_estado_num ASC, fecalta2 DESC) AS num
        FROM (
            SELECT DISTINCT y.*,
                (CASE WHEN y.tpoemp IN ('01') THEN 'PPNNSN'
                      WHEN y.tpoemp IN ('02') THEN 'PPNNCN'
                      WHEN y.tpoemp IN ('07') THEN 'EIRL'
                      WHEN y.tpoemp IN ('08') THEN 'SOCIEDAD CIVIL'
                      WHEN y.tpoemp IN ('09') THEN 'SOCIEDAD IRREGULAR'
                      WHEN y.tpoemp IN ('11') THEN 'ASOCIACION'
                      WHEN y.tpoemp IN ('19') THEN 'CENTROS EDUCATIVO'
                      WHEN y.tpoemp IN ('26') THEN 'SA'
                      WHEN y.tpoemp IN ('28') THEN 'SCRL'
                      WHEN y.tpoemp IN ('39') THEN 'SAC'
                      WHEN y.tpoemp IN ('43') THEN 'SMRL' ELSE 'OTROS' END) AS cl_tpoemp,
                (CASE WHEN y.estado IN ('00')           THEN 'ACTIVO'
                      WHEN y.estado IN ('01','02')      THEN 'BAJA PROV.'
                      WHEN y.estado IN ('03')           THEN 'SUSPENSION TEMP.'
                      WHEN y.estado IN ('04')           THEN 'ANUL.PROVI.-ACTO ILICITO'
                      WHEN y.estado IN ('10','11','12') THEN 'CASERIO'
                      WHEN y.estado IN ('21')           THEN 'OTROS OBLIG.'
                      WHEN y.estado IN ('22')           THEN 'INHABILITADO'
                      WHEN y.estado IN ('30','31')      THEN 'ANULACION'
                      WHEN y.estado IN ('32')           THEN 'PEND. INI. ACTIV.' ELSE 'MISSING' END) AS cl_estado,
                (CASE WHEN y.estado IN ('00') THEN 1 ELSE 0 END) AS cl_estado_num
            FROM (
                SELECT DISTINCT x.codmes, x.tip_doc, x.key_value,
                    (CASE WHEN (CAST(SUBSTR(y.fecalta2,1,6) AS INTEGER) > cast(x.codmes AS integer)) THEN 'SIN_DATO' ELSE y.tipcontribuyente     END) AS tpoemp,
                    (CASE WHEN (CAST(SUBSTR(y.fecalta2,1,6) AS INTEGER) > cast(x.codmes AS integer)) THEN 'SIN_DATO' ELSE y.estadocontribuyente  END) AS estado,
                    (CASE WHEN (CAST(SUBSTR(y.fecalta2,1,6) AS INTEGER) > cast(x.codmes AS integer)) THEN 'SIN_DATO' ELSE y.ubigeo               END) AS ubigeo,
                    (CASE WHEN (CAST(SUBSTR(y.fecalta2,1,6) AS INTEGER) > cast(x.codmes AS integer)) THEN ''         ELSE y.fecalta2             END) AS fecalta2,
                    (CASE WHEN (CAST(SUBSTR(y.fecalta2,1,6) AS INTEGER) > cast(x.codmes AS integer)) THEN 'SIN_DATO' ELSE y.ciiu                 END) AS ciiu
                FROM uni_mad x
                LEFT JOIN (
                    SELECT z.*
                    FROM (
                        SELECT x.*,
                            (CASE WHEN x.flg_ruc = 10 THEN '1'
                                  WHEN x.flg_ruc = 15 THEN '1'
                                  WHEN x.flg_ruc = 17 THEN '1' ELSE '2' END) AS tipdoc,
                            (CASE WHEN (x.flg_ruc = 10 OR x.flg_ruc = 15 OR x.flg_ruc = 17) THEN y.key_value ELSE x.ruc_value END) AS nrodoc
                        FROM (SELECT a.*, cast(extract(year FROM a.fecalta)*10000 + extract(month FROM a.fecalta)*100 + extract(day FROM a.fecalta) AS varchar(8)) AS fecalta2
                              FROM e_perm_aws.t_mst_princ_sunat_rsk a) x
                        LEFT JOIN (
                            SELECT *,
                                ROW_NUMBER() OVER (PARTITION BY tip_doc, key_value ORDER BY fecproceso, fecinicio, estadoregistro, ruc_value DESC) AS num
                            FROM e_perm_aws.t_mst_sec_sunat_rsk) y
                            ON (x.ruc_value = y.ruc_value) AND y.num = 1
                        WHERE x.fecalta2 <> ''
                    ) z
                    INNER JOIN uni_mad_key k
                        ON z.tipdoc = k.tip_doc AND z.nrodoc = k.key_value) y
                ON (x.tip_doc = y.tipdoc AND x.key_value = y.nrodoc)
            ) y
        ) a
    ) a
    WHERE a.num = 1
),
filtro_sunat2 AS (
    SELECT a.codmes, a.tip_doc, a.key_value,
           b.tpoemp, b.estado, b.fecalta2, b.ciiu, b.ubigeo, b.cl_tpoemp, b.cl_estado, b.cl_estado_num
    FROM uni_mad a
    LEFT JOIN filtro_sunat b
        ON a.codmes = b.codmes AND a.tip_doc = b.tip_doc AND a.key_value = b.key_value
)
SELECT DISTINCT
    a.codmes,
    a.tip_doc,
    a.key_value,
    a.tpoemp,
    a.estado,
    a.fecalta2,
    a.ciiu,
    a.ubigeo,
    a.cl_tpoemp,
    a.cl_estado,
    a.cl_estado_num,
    a.giro_restringido,
    a.ubigeo_restringido,
    CASE WHEN a.tpoemp = '01' THEN 'PPNN_SN' WHEN a.tpoemp = '02' THEN 'PPNN_CN' ELSE 'PPJJ' END AS tipo_personeria,
    CASE WHEN a.cl_estado = 'ACTIVO' AND a.tpoemp <> '01' AND a.ubigeo_restringido <> 1 AND a.giro_restringido <> 1
          AND (trim(a.ubigeo) NOT IN ('SIN_DATO','')) THEN 1 ELSE 0 END AS flag_bpe_v1,
    CASE WHEN a.cl_estado = 'ACTIVO' AND a.ubigeo_restringido <> 1 AND a.giro_restringido <> 1
          AND (trim(a.ubigeo) NOT IN ('SIN_DATO','')) THEN 1 ELSE 0 END AS flag_bpe_v2
FROM (
    SELECT a.*,
        CASE WHEN c.flag_aceptanuevos = 'Restringido' THEN 1
             WHEN c.flag_aceptanuevos = 'Atendido'    THEN 0 ELSE -1 END AS giro_restringido,
        CASE WHEN d.flag_zonabpe = 'Atendido'    THEN 0
             WHEN d.flag_zonabpe = 'Restringido' THEN 1 ELSE -1 END AS ubigeo_restringido
    FROM filtro_sunat2 a
    LEFT JOIN (SELECT codigoacteconomica, max(flag_aceptanuevos) AS flag_aceptanuevos FROM e_perm_aws.t_mst_bpe_giros_restringidos GROUP BY 1) c
        ON a.ciiu = c.codigoacteconomica
    LEFT JOIN (SELECT cod_ubigeo, max(flag_zonabpe) AS flag_zonabpe FROM e_perm_aws.t_mst_bpe_ubigeos_restringidos GROUP BY 1) d
        ON a.ubigeo = d.cod_ubigeo
) a
