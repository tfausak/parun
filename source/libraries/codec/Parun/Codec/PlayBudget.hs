{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PlayBudget where

import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PlayBudget as PlayBudget

-- | Both fields required: this is a game state's record of a budget already
-- granted, and neither has a default the rules give.
codec :: Codec.Codec PlayBudget.PlayBudget
codec = Fields.object $ do
  remaining <- Fields.required "remaining" Common.natural PlayBudget.remaining
  covers <- Fields.required "covers" (Common.set ObjectId.codec) PlayBudget.covers
  pure PlayBudget.MkPlayBudget {PlayBudget.remaining = remaining, PlayBudget.covers = covers}
