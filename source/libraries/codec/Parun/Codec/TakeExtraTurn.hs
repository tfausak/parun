{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.TakeExtraTurn where

import qualified Parun.Codec.PhaseSelector as PhaseSelector
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.TakeExtraTurn as TakeExtraTurn

-- | A bare object keyed by the record's field names. The tag that picks it is
-- written by Parun.Codec.Effect's TakeExtraTurn arm. `count` defaults to the one
-- turn all but Ral Zarek print.
codec :: Codec.Codec TakeExtraTurn.TakeExtraTurn
codec = Fields.object $ do
  player <- Fields.required "player" PlayerRef.codec TakeExtraTurn.player
  skips <- Fields.required "skips" (Common.set PhaseSelector.codec) TakeExtraTurn.skips
  count <- Fields.defaulted "count" TakeExtraTurn.defaultCount Quantity.codec TakeExtraTurn.count
  pure
    TakeExtraTurn.MkTakeExtraTurn
      { TakeExtraTurn.player = player,
        TakeExtraTurn.skips = skips,
        TakeExtraTurn.count = count
      }
