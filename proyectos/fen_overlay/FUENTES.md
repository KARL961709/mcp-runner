# FUENTES — fundamento bibliográfico del overlay FEN

Todas verificadas en fuente primaria (regla: **no inventar citas**; lo no confirmado va marcado). Sostiene el requisito
SR 11-7 de que el juicio experto sea "consistent with published research and sound industry practice".

## Núcleo cuantitativo
- **Merton, R. (1974).** On the Pricing of Corporate Debt. *Journal of Finance* 29(2):449–470. — modelo de umbral estructural.
- **Vasicek, O. (2002).** Loan Portfolio Value. *Risk*, dic-2002:160–162. — factor único, PD condicional en forma cerrada.
- **Gordy, M. (2003).** A risk-factor model foundation for ratings-based bank capital rules. *J. Financial Intermediation* 12(3):199–232. — base del ASRF/IRB.
- **BCBS (2005).** An Explanatory Note on the Basel II IRB Risk Weight Functions. — fórmula `Φ[(Φ⁻¹(PD)+√ρ·M)/√(1−ρ)]`. https://www.bis.org/bcbs/irbriskweight.pdf
- **Basilea, marco consolidado CRE31** — correlaciones retail: hipotecario **0,15** (CRE31.14); QRRE **0,04** (CRE31.15); **other retail** 0,03–0,16 decreciente en PD (CRE31.16). → **ρ=0,15 es la HIPOTECARIA; consumo/PP = other retail (~0,04)**.
- **Carlehed & Petrov (2012).** A methodology for PIT–TTC PD decomposition. *J. Risk Model Validation* 6(3):3–25. DOI 10.21314/JRMV.2012.091. — PIT = probit-shift del ancla TTC por factor macro = el `ft`.
- **Hadar & Russell (1969).** Rules for Ordering Uncertain Prospects. *AER* 59(1):25–34. — FOSD (propiedad, no mandato).

## Identificación · overlay · gobierno
- **Card & Krueger (1994).** Minimum Wages and Employment. *AER* 84(4):772–793. — DiD aplicado canónico.
- **Bertrand, Duflo & Mullainathan (2004).** How Much Should We Trust DiD Estimates? *QJE* 119(1):249–275. — inferencia/correlación serial.
- **ECB Banking Supervision (jul-2024).** IFRS 9 overlays and model improvements for novel risks. — overlay = "adjustment after the model is operated"; legítimo con "sound methodologies... strong governance and transparency". https://www.bankingsupervision.europa.eu/ecb/pub/pdf/ssm.IFRS9novelrisks_202407~5e0eb30b5c.en.pdf
- **Fed/OCC SR 11-7 (2011).** Supervisory Guidance on Model Risk Management. — permite "well-supported, judgmental, 'conservative' adjustments to model output"; effective challenge; validación independiente. https://www.federalreserve.gov/supervisionreg/srletters/sr1107.htm
- **Robinson, W.S. (1950).** Ecological Correlations and the Behavior of Individuals. *Am. Sociological Review* 15(3):351–357. DOI 10.2307/2087176. — falacia ecológica.
- **Stiglitz & Weiss (1981).** Credit Rationing in Markets with Imperfect Information. *AER* 71(3):393–410. — selección adversa (precio → composición del pool).
- *NO verificado:* norma **SBS Perú** de riesgo de modelos — ubicarla antes de citarla (SR 11-7 es de EE.UU., estándar de facto).

## Empírica clima-crédito
- **Cashin, Mohaddes & Raissi (2017).** Fair weather or foul? The macroeconomic effects of El Niño. *J. International Economics* 106:37–54. — FEN → inflación (mayor si alimentos pesan en IPC) + caída de PBI. *(Perú NO está como país propio en el GVAR; usar Chile como análogo.)*
- **Brunner (2002).** El Niño and World Primary Commodity Prices. *REStat* 84(1):176–183. — +1σ ENSO → +3,5–4pp inflación de commodities.
- **BIS Working Paper 1276 (2025)** (Aguirre, Ledesma, Perez & Rojas). — **Perú**: El Niño = shock de oferta inflacionario y contractivo; primario (agro/pesca) golpeado de inmediato. Ancla local macro. https://ideas.repec.org/p/bis/biswps/1276.html
- **BCBS (2021).** Climate-related risk drivers and their transmission channels. — físico vs transición; canal directo/micro y indirecto/macro. **El solape precio↔físico es REAL** (el FEN sube precios porque destruye oferta física). https://www.bis.org/bcbs/publ/d517.htm
- **ECB Working Paper 3224 (2025).** Physical climate risk, credit risk and lending activity. — firma inundada **+0,7 pp** de pasar a non-performing el trimestre siguiente. https://www.ecb.europa.eu/pub/pdf/scpwps/ecb.wp3224~8735166667.en.pdf

## ENSO → crédito (cierra la brecha de validez externa)
- **Collier, Katchova & Skees (2011).** Loan portfolio performance and El Niño, an intervention analysis. *Agricultural Finance Review* 71(1):98–119. — **MFI norte de Perú (Piura)**, 1994–2008: El Niño → reestructurados **de 0,5% a +3,6% adicional** del portafolio. El ancla Perú-específica. https://www.emerald.com/afr/article-abstract/71/1/98/59647/
- **De Marco & Limodio.** The Financial Transmission of a Climate Shock: El Niño and US Banks. *Journal of Financial Economics* (SSRN 4279194 / CEPR DP17909). — El Niño → menor crédito hipotecario; bancos expuestos recortan incluso en condados no afectados. https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4279194
- **"Climate shocks and banking sector stability: Evidence from ENSO"** *Ecological Economics* (2025). — 51 países, 2000–2020; adverso en banca, **más en Latinoamérica**; **NPL = canal principal**. *(Autor no confirmado 100% esta pasada.)* https://www.sciencedirect.com/science/article/abs/pii/S0921800925002654
- **Collier & Skees (2012).** Increasing the resilience of financial intermediaries through portfolio-level insurance. *Natural Hazards*. — MFI Perú, seguro de portafolio.

## Caveats a declarar
- Collier et al. mide **reestructurados**, no PD literal; De Marco-Limodio es **oferta de crédito**, no PD del prestatario.
- No existe (no hallado) un "El Niño → **PD bancaria** puntual en Perú"; el link se sostiene por **composición + evidencia ENSO→crédito directa**.
- Overlay ECL→pricing y S-W→pricing geográfico son **extensiones legítimas**, no autoridad literal.
