-- c_2609_part. Relacion particion p_codmes vs dato codmes en vcbankv3_repro (para podar bien el driver).
--   Si p_codmes='202609' contiene solo codmes='202609' -> p_codmes=codmes, podo el driver por p_codmes='202609'.
--   Si aparecen otros codmes bajo un p_codmes -> hay desfase y ajusto el prune. Sin poda buena, el driver escanea 35 meses.
SELECT CAST(p_codmes AS varchar) AS p_codmes, CAST(codmes AS varchar) AS codmes, COUNT(*) AS n
FROM disc_riesgos.scr_vcbankv3_repro_
WHERE CAST(p_codmes AS varchar) IN ('202608', '202609')
GROUP BY CAST(p_codmes AS varchar), CAST(codmes AS varchar)
ORDER BY p_codmes, codmes
