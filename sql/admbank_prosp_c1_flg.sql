-- QA[1] CONTEO + flg_camp: total 202608, entran (1) vs caen (0). n_cae debe ~ caidas cruzadas.
SELECT flg_camp, COUNT(*) AS n, ROUND(100.0*COUNT(*)/SUM(COUNT(*)) OVER(),1) AS pct FROM disc_model_owner.admbank_prosp_202608 GROUP BY flg_camp ORDER BY flg_camp
