{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.DieRollR where

import qualified Parun.Codec.ControllerRelation as ControllerRelation
import qualified Parun.Codec.DieRollRewrite as DieRollRewrite
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.DieRollR as DieRollR

codec :: Codec.Codec DieRollR.DieRollR
codec = Fields.object $ do
  whose <- Fields.required "whose" ControllerRelation.codec DieRollR.whose
  rewrite <- Fields.required "rewrite" DieRollRewrite.codec DieRollR.rewrite
  pure
    DieRollR.MkDieRollR
      { DieRollR.whose = whose,
        DieRollR.rewrite = rewrite
      }
