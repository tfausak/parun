{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.CoinFlipTrigger where

import qualified Parun.Codec.FlipOutcome as FlipOutcome
import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.CoinFlipTrigger as CoinFlipTrigger

-- | A bare object keyed by the record's field names. Both keys are required:
-- neither a seat nor an outcome has a reading every printing shares.
codec :: Codec.Codec CoinFlipTrigger.CoinFlipTrigger
codec = Fields.object $ do
  player <- Fields.required "player" PlayerRelation.codec CoinFlipTrigger.player
  outcome <- Fields.required "outcome" FlipOutcome.codec CoinFlipTrigger.outcome
  pure CoinFlipTrigger.MkCoinFlipTrigger {CoinFlipTrigger.player = player, CoinFlipTrigger.outcome = outcome}
