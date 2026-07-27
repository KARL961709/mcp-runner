-- 2z_b_mad_union.sql | union de los 6 tramos | 201506-202606
CREATE TABLE disc_model_owner.ds_adm_bpe_bankbn_mad AS
SELECT * FROM disc_model_owner.ds_adm_bpe_bankbn_mad_t1
UNION ALL
SELECT * FROM disc_model_owner.ds_adm_bpe_bankbn_mad_t2
UNION ALL
SELECT * FROM disc_model_owner.ds_adm_bpe_bankbn_mad_t3
UNION ALL
SELECT * FROM disc_model_owner.ds_adm_bpe_bankbn_mad_t4
UNION ALL
SELECT * FROM disc_model_owner.ds_adm_bpe_bankbn_mad_t5
UNION ALL
SELECT * FROM disc_model_owner.ds_adm_bpe_bankbn_mad_t6
