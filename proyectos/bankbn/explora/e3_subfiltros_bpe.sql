-- e3 SUBFILTROS: descomposicion de flag_bpe_parcial (lo que hay dentro de NO_BPE)
SELECT flag_bpe_parcial, COUNT(*) AS n
FROM disc_model_owner.ds_adm_bpe_bankbn_drivers
GROUP BY flag_bpe_parcial
ORDER BY n DESC
