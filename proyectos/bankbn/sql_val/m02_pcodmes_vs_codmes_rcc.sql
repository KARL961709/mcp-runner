-- m02_pcodmes_vs_codmes_rcc.sql | en el RCC p_codmes y codmes son el mismo mes? gatea el corte disjunto y la alineacion de rangos del build
SELECT fuente,
       CASE WHEN cast(codmes AS varchar) = cast(p_codmes AS varchar) THEN 'IGUAL' ELSE 'DISTINTO' END AS relacion,
       count(1)                       AS filas,
       min(cast(p_codmes AS varchar)) AS p_min,
       max(cast(p_codmes AS varchar)) AS p_max,
       min(cast(codmes AS varchar))   AS c_min,
       max(cast(codmes AS varchar))   AS c_max
FROM (
    SELECT 'D_PERM' AS fuente, codmes, p_codmes
    FROM d_perm_aws.t_fact_report_rcc_rsk
    WHERE p_codmes IN ('201405','201705','201812','201901','202105','202605')
    UNION ALL
    SELECT 'E_PERM', codmes, p_codmes
    FROM e_perm_aws.t_fact_report_rcc_rsk
    WHERE p_codmes IN ('201901','202105','202305','202506','202606')
) u
GROUP BY fuente, CASE WHEN cast(codmes AS varchar) = cast(p_codmes AS varchar) THEN 'IGUAL' ELSE 'DISTINTO' END
ORDER BY fuente, relacion
