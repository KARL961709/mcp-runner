-- 04 t_mst_denton_pesos_rsk
CREATE EXTERNAL TABLE IF NOT EXISTS <base_cal>.t_mst_denton_pesos_rsk (
  variante  string,
  fase      int,
  k         int,
  origen    string,
  rel       int,
  peso      double
)
STORED AS PARQUET
LOCATION 's3://<bucket>/t_mst_denton_pesos_rsk/'
