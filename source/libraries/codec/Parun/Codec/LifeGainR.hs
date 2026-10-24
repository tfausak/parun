{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.LifeGainR where

import qualified Parun.Codec.ControllerRelation as ControllerRelation
import qualified Parun.Codec.LifeGainRewrite as LifeGainRewrite
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.LifeGainR as LifeGainR

codec :: Codec.Codec LifeGainR.LifeGainR
codec = Fields.object $ do
  whose <- Fields.required "whose" ControllerRelation.codec LifeGainR.whose
  rewrite <- Fields.required "rewrite" LifeGainRewrite.codec LifeGainR.rewrite
  pure
    LifeGainR.MkLifeGainR
      { LifeGainR.whose = whose,
        LifeGainR.rewrite = rewrite
      }
