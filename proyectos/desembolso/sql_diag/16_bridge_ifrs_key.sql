-- 16_bridge_ifrs_key.sql | prueba de llave para unir d_perm_aws.user_desembolso (llave = key_value, hash sha256 de 64 chars) con e_perm_aws.t_ifrs_rcddeta_rsk (trae cod_cuc y nu_docu, NO key_value). Para un solo mes (p_codmes 202606) hashea candidatos del documento y del cuc y cuenta cuantos ids del mes caen en el set de key_value de user_desembolso. El metodo correcto da match alto, los demas ~0. Solo devuelve conteos agregados, nunca el documento (nu_docu es PII). READ-ONLY
WITH u AS (
  SELECT DISTINCT key_value FROM d_perm_aws.user_desembolso
),
cand AS (
  SELECT 'docu_lower' AS metodo, lower(to_hex(sha256(to_utf8(nu_docu)))) AS h FROM e_perm_aws.t_ifrs_rcddeta_rsk WHERE p_codmes = '202606' AND nu_docu IS NOT NULL
  UNION ALL
  SELECT 'docu_upper', upper(to_hex(sha256(to_utf8(nu_docu)))) FROM e_perm_aws.t_ifrs_rcddeta_rsk WHERE p_codmes = '202606' AND nu_docu IS NOT NULL
  UNION ALL
  SELECT 'docu_trim_lower', lower(to_hex(sha256(to_utf8(trim(nu_docu))))) FROM e_perm_aws.t_ifrs_rcddeta_rsk WHERE p_codmes = '202606' AND nu_docu IS NOT NULL
  UNION ALL
  SELECT 'cuc_lower', lower(to_hex(sha256(to_utf8(cod_cuc)))) FROM e_perm_aws.t_ifrs_rcddeta_rsk WHERE p_codmes = '202606' AND cod_cuc IS NOT NULL
)
SELECT c.metodo,
  count(DISTINCT c.h) AS ids_mes,
  count(DISTINCT CASE WHEN u.key_value IS NOT NULL THEN c.h END) AS ids_en_userdesemb
FROM cand c
LEFT JOIN u ON u.key_value = c.h
GROUP BY c.metodo
ORDER BY ids_en_userdesemb DESC
