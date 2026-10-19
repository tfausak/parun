{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.PlayBudget where

import qualified Pawl.Codec.ObjectId as ObjectId
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.PlayBudget as PlayBudget

-- | Both fields required: this is a game state's record of a budget already
-- granted, and neither has a default the rules give.
codec :: Codec.Codec PlayBudget.PlayBudget
codec = Fields.object $ do
  remaining <- Fields.required "remaining" Common.natural PlayBudget.remaining
  covers <- Fields.required "covers" (Common.set ObjectId.codec) PlayBudget.covers
  pure PlayBudget.MkPlayBudget {PlayBudget.remaining = remaining, PlayBudget.covers = covers}
