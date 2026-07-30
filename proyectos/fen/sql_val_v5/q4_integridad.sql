-- q4 INTEGRIDAD. Esperado: n=1890, dup=0, sin_ubigeo=1, nulos=0, marcados=1497
SELECT count(*)                                                              AS n_filas,
       count(*) - count(DISTINCT cod_ubigeo)                                 AS dup_ubigeo,
       sum(CASE WHEN cod_ubigeo = 'SIN_UBIGEO' THEN 1 ELSE 0 END)            AS sin_ubigeo,
       sum(CASE WHEN r_label IS NULL OR d_label IS NULL
                  OR r_driver IS NULL OR r_evidencia IS NULL
                  OR d_evidencia IS NULL THEN 1 ELSE 0 END)                  AS nulos_criticos,
       sum(marcado)                                                          AS n_marcados,
       sum(CASE WHEN r_nivel = 0 AND d_nivel = 0 AND marcado = 1 THEN 1 ELSE 0 END) AS marcado_inconsistente,
       sum(CASE WHEN gate_cronica = 1 AND r_nivel > 0 THEN 1 ELSE 0 END)     AS gate_inconsistente
FROM disc_model_owner.fen_score_v5
