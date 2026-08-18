-- 01. RECONCILIACION CONTRA LA FUENTE
--   una fila escrita por cada fila de scr_vcnbank_rsk en la ventana. dif_filas
--   distinto de 0 en cualquier mes es FALLA: o el tramo no corrio, o corrio dos
--   veces. Con INSERT INTO lo segundo es posible y no avisa
SELECT coalesce(s.codmes, d.codmes)                                              AS codmes,
       d.n_fuente,
       s.n_escritas,
       coalesce(s.n_escritas, 0) - coalesce(d.n_fuente, 0)                       AS dif_filas,
       s.n_sin_score,
       s.n_nodo_nulo
  FROM (SELECT p_codmes                                                          AS codmes,
               COUNT(*)                                                          AS n_escritas,
               SUM(CASE WHEN prob_modelo_cal IS NULL THEN 1 ELSE 0 END)          AS n_sin_score,
               SUM(CASE WHEN nodo_calc IS NULL THEN 1 ELSE 0 END)                AS n_nodo_nulo
          FROM disc_model_owner.scr_univ_vcnbank_tc_cal
         GROUP BY p_codmes) s
  FULL JOIN (SELECT p_codmes                                                     AS codmes,
                    COUNT(*)                                                     AS n_fuente
               FROM e_perm_aws.scr_vcnbank_rsk
              WHERE p_codmes BETWEEN '202401' AND '202607'
              GROUP BY p_codmes) d
         ON d.codmes = s.codmes
 ORDER BY 1
