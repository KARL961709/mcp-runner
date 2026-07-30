-- s01 CONTRATO DE LAS LLAVES -- codunico de las RM vs cuc_num de dim_cliente vs codunico de apicliente
--     si los largos no calzan, el puente falla por padding y no por falta de dato
SELECT 'rm_estandarizada.codunico'   AS fuente, count(*) AS n_filas,
       count(DISTINCT trim(codunico)) AS n_llaves,
       min(length(trim(codunico)))    AS len_min, max(length(trim(codunico))) AS len_max
FROM d_perm_aws.t_rm_direccion_estandarizada
UNION ALL
SELECT 'rm_noestandarizada.codunico', count(*), count(DISTINCT trim(codunico)),
       min(length(trim(codunico))), max(length(trim(codunico)))
FROM d_perm_aws.t_rm_direccion_noestandarizada
UNION ALL
SELECT 'apicliente.codunico', count(*), count(DISTINCT trim(codunico)),
       min(length(trim(codunico))), max(length(trim(codunico)))
FROM d_perm_aws.t_dmdireccion_apicliente
UNION ALL
SELECT 'dim_cliente.cuc_num', count(*), count(DISTINCT trim(cuc_num)),
       min(length(trim(cuc_num))), max(length(trim(cuc_num)))
FROM e_perm_aws.t_dim_cliente
WHERE tipo_persona_host = '01'
ORDER BY 1
