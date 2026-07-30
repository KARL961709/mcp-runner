-- d04 EL NUMERO QUE DECIDE SI IBK+ PUEDE SER VARIABLE MACRO
--     ventana de fit = 201901-202504 excl 2020 (64m) -- train del holdout OOT = codmes <= 202210
WITH m AS (
  SELECT DISTINCT 'nacional' AS serie, codmes FROM disc_model_owner.ibk_indice_nacional_nominal
  UNION ALL
  SELECT DISTINCT 'regional' AS serie, codmes FROM disc_model_owner.ibk_indice_regional_categoria
)
SELECT serie,
       count(*)                                                                       AS n_meses,
       min(codmes)                                                                    AS mes_min,
       max(codmes)                                                                    AS mes_max,
       sum(CASE WHEN codmes BETWEEN '201901' AND '202504'
                 AND substr(codmes, 1, 4) <> '2020' THEN 1 ELSE 0 END)                AS n_en_fit_64m,
       sum(CASE WHEN codmes <= '202210' THEN 1 ELSE 0 END)                            AS n_en_train_oot
FROM m
GROUP BY serie
ORDER BY serie
