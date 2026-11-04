{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.NextStepOf where

import qualified Parun.Codec.Phase as Phase
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.NextStepOf as NextStepOf
import qualified Parun.Types.PlayerRef as PlayerRef.Type
import qualified Parun.Types.PlayerRelation as PlayerRelation

-- | A bare object keyed by the record's field names; a player left out is CR
-- 109.5's "you".
codec :: Codec.Codec NextStepOf.NextStepOf
codec = Fields.object $ do
  step <- Fields.required "step" Phase.codec NextStepOf.step
  player <- Fields.defaulted "player" (PlayerRef.Type.Relative PlayerRelation.You) PlayerRef.codec NextStepOf.player
  pure NextStepOf.MkNextStepOf {NextStepOf.step = step, NextStepOf.player = player}
