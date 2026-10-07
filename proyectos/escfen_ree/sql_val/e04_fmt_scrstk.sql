-- e04. formato llave scr_stk_ree a 202610: tip_doc y largo/bytes de key_value
SELECT tip_doc,
  COUNT(*) AS n,
  MIN(length(key_value)) AS min_len_kv,
  MAX(length(key_value)) AS max_len_kv,
  MAX(length(to_utf8(key_value))) AS max_bytes_kv
FROM disc_model_owner.scr_stk_ree_pp_cal_202610
WHERE codmes = '202610'
GROUP BY tip_doc
ORDER BY n DESC
