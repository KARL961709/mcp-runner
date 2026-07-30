-- v5_00 DROP -- correr SOLO con -Only v5_00_drop y solo si hay que re-crear
-- OJO: el DROP no borra S3. Antes de re-crear hay que vaciar <S3_DATOS>/fen/fen_score_v5/
-- o el CTAS falla por location no vacia.
DROP TABLE IF EXISTS disc_model_owner.fen_score_v5
