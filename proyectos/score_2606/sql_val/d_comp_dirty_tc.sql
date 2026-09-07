-- d_comp_dirty_tc. Composicion de dsc_flg_malo_12m de admitidos TC (IBK, 202606-207) desde enr_admtcbk_2_v2.
--   flg_clean=0 (dirty) desglosado por categoria -> muestra QUE arma el dirty desplegado y que brazos replicar.
--   flg_clean=0 total debe ~= 18240 (n_dep_dirty del diagnostico del lag). clean=1 = las 5 categorias modelables.
SELECT flg_clean, dsc_flg_malo_12m, COUNT(*) AS n
FROM disc_model_owner.enr_admtcbk_2_v2
WHERE flg_ibk = 1 AND CAST(codmes AS varchar) BETWEEN '202606' AND '202607'
GROUP BY flg_clean, dsc_flg_malo_12m
ORDER BY flg_clean, n DESC
