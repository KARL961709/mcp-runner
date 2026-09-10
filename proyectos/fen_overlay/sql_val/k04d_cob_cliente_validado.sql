-- k04d: universo VC 202608 vs enr_dataset_cliente_reniec_validado (dataset cliente validado, posible fuente mas completa/cercana al banco). Si cubre mas que 9.1M, hay domicilio recuperable por otra via. Read-only, 1 fila. OJO: si esta tabla no tiene key_value, k04a lo dira y esta fallara sin tumbar al resto
SELECT
  count(*)                                            AS n_univ,
  count(t.key_value)                                  AS n_en_cliente_validado,
  round(100.0 * count(t.key_value) / count(*), 2)     AS pct
FROM disc_model_owner.scr_vcadmbnk_final_hist_rsk_cal_2606_2608 u
LEFT JOIN disc_model_owner.enr_dataset_cliente_reniec_validado t ON u.key_value = t.key_value
WHERE u.codmes = '202608'
