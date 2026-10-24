{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PlayerDrawsNthCard where

import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PlayerDrawsNthCard as PlayerDrawsNthCard

-- | A bare object keyed by the record's field names, replacing the two-element
-- array this payload used to be. The ordinal is ELIDED when absent, so "a card"
-- writes no key.
codec :: Codec.Codec PlayerDrawsNthCard.PlayerDrawsNthCard
codec = Fields.object $ do
  player <- Fields.required "player" PlayerRelation.codec PlayerDrawsNthCard.player
  nth <- Fields.defaulted "nth" Nothing (Common.maybe Common.natural) PlayerDrawsNthCard.nth
  pure
    PlayerDrawsNthCard.MkPlayerDrawsNthCard
      { PlayerDrawsNthCard.player = player,
        PlayerDrawsNthCard.nth = nth
      }
