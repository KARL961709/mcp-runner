-- consolida los 7 tramos en ds_adm_bpe_bankbn_po
CREATE TABLE disc_model_owner.ds_adm_bpe_bankbn_po AS
SELECT * FROM disc_model_owner.ds_adm_bpe_bankbn_po_t1
UNION ALL
SELECT * FROM disc_model_owner.ds_adm_bpe_bankbn_po_t2
UNION ALL
SELECT * FROM disc_model_owner.ds_adm_bpe_bankbn_po_t3
UNION ALL
SELECT * FROM disc_model_owner.ds_adm_bpe_bankbn_po_t4
UNION ALL
SELECT * FROM disc_model_owner.ds_adm_bpe_bankbn_po_t5
UNION ALL
SELECT * FROM disc_model_owner.ds_adm_bpe_bankbn_po_t6
UNION ALL
SELECT * FROM disc_model_owner.ds_adm_bpe_bankbn_po_t7
