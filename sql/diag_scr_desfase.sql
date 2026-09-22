-- diag_scr_desfase.sql | caracteriza el desfase temporal del score de admision. Por p_codmes (mes campana/alta): que codmes(RCC) usa y cuando se replico (fec_replica). Responde el cuestionamiento del desfase de 2 meses: si fec_replica ~ p_codmes y codmes=p_codmes-1, el score se produjo en campana con RCC de 1 mes atras (sin look-ahead solo si la RCC de p_codmes-1 ya estaba disponible ahi). Read-only, agregado.
SELECT p_codmes,
  codmes,
  COUNT(*) AS n,
  MIN(fec_replica) AS min_fec_replica,
  MAX(fec_replica) AS max_fec_replica
FROM e_perm_aws.scr_admbankbpe_rsk
WHERE modelo = 'ADMBANKBPE' AND p_codmes >= '202603'
GROUP BY p_codmes, codmes
ORDER BY p_codmes, codmes
