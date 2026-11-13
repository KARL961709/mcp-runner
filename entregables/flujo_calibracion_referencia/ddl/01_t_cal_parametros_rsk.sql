-- 01 t_cal_parametros_rsk
CREATE EXTERNAL TABLE IF NOT EXISTS <base_cal>.t_cal_parametros_rsk (
  modelo     string,
  parametro  string,
  valor      string,
  nro_carga  int,
  ts_carga   timestamp
)
PARTITIONED BY (p_codmes string)
STORED AS PARQUET
LOCATION 's3://<bucket>/t_cal_parametros_rsk/'
