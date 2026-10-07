# escfen_ree — escfen consolidado Comportamental PP Reenganche (202610)

Mismo tratamiento FEN que el VC escfen, pero para UN producto (Reenganche).

## Fuentes (dadas por el usuario)
- **freeze** (ft congelado): `e_perm_aws.t_agg_comppree_rsk`, campo `prob_modelo_cal`
- **no_freeze** (ft vivo oct): `disc_model_owner.scr_stk_ree_pp_cal_202610`, campo `prob_modelo_cal`
- Salida: `disc_model_owner.scr_vcadmbnk_... ` NO — aqui la tabla es `disc_model_owner.scr_stk_ree_pp_cal_202610_escfen`

## Cadena de calibracion (de calibracion_ree.json + ree_scoring/71, reproduce vigente a 1e-10)
```
pd_raw -> BetaCal(seg) -> Phi_inv + probit_delta_seg + delta_0 -> Vasicek PIT(f_t) -> prob_modelo_cal
```
- BetaCal: pd_cal = 1/(1+exp(-( m + a*ln(p) - b*ln(1-p) )))
- PIT: prob_modelo_cal = Phi( ( Phi_inv(pd_cal) + probit_delta_seg + delta_0 - sqrt(rho)*lambda*f_t ) / sqrt(1-rho) )
- TTC (f_t=0): Phi( Phi_inv(pit) + sqrt(rho)*lambda*f_t / sqrt(1-rho) )  (macro-free, usa el f_t guardado)

## Constantes (CONGELADAS, no reajustar)
- rho = 0.038030115964094044 ; sqrt(1-rho) = 0.9808006 ; sqrt(rho) = 0.1950131 ; sqrt(rho)/sqrt(1-rho) = 0.198831
- lambda = 1.0 ; delta_0 = 0.034261721611022956 ; LRA = 0.04226346409008948
- seg DEP    : m=-1.4235902271832188 a=1.4307409240924087 b=0.11673242216482149 probit_delta=0.061973725544583
- seg NO DEP : m=-1.8712301290911784 a=1.12194919105907   b=0.5587876581505312  probit_delta=0.10257577255744288
- seg_col = trf_tipo_ingreso_dep (DEP / NO DEP) ; f_t_col = trf_f_t ; clip pit [1e-4, 1-1e-4]

## FEN moderado (identico al VC escfen)
- ep = 0.5*max(R/5, 0.10) + 0.5*max(s_norm, 0)
- shift = 0.77831 * ep * (1 - 0.70*rec_d)   (gamma=4.2, rec 70%)
- pd_pit_fen = Phi( Phi_inv(pit) + shift )
- geo: reest (mca_bd_reniec_xy_r_reest) + fallback nombre dist/prov/dep ; s (fen_s_indirecto_empleo_2026) ; rec_d (fen_recd_2026)
- sin gate Pacifico (uso pricing, piso 0.10 a todos)

## Campos finales por producto (6 PD + puntuacion c/u)
pd_raw, pd_ttc, pd_pit_freeze, pd_pit, pd_pit_freeze_fen, pd_pit_fen

## Estado
- [ ] exploracion sql_val e01-e05 (estructura t_agg + perfil scr_stk + llaves)
- [ ] wave2: perfil t_agg + cardinalidad join + ft freeze vs vivo
- [ ] build sql_prod + QA
