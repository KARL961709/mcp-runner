-- 03 scr_cal_cppibkren_rsk
CREATE EXTERNAL TABLE IF NOT EXISTS <base_cal>.scr_cal_cppibkren_rsk (
  cod_mes                    string,
  cod_tip_doc                string,
  key_value                  string,
  cod_cli                    string,
  prob_modelo                double,
  puntuacion                 int,
  factor_macro_pp            double,
  factor_macro_freeze_pp     double,
  prob_modelo_cal_pp         double,
  puntuacion_cal_pp          int,
  prob_modelo_cal_freeze_pp  double,
  puntuacion_cal_freeze_pp   int,
  prob_modelo_cal_smacro_pp  double,
  puntuacion_cal_smacro_pp   int,
  id_calibracion             string,
  extra_01                   string,
  extra_02                   string,
  extra_03                   string,
  extra_04                   string,
  extra_05                   string,
  extra_06                   string,
  extra_07                   string,
  extra_08                   string
)
PARTITIONED BY (p_codmes string, p_fecdia string)
STORED AS PARQUET
LOCATION 's3://<bucket>/scr_cal_cppibkren_rsk/'
