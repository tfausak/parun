{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.AnyNumberDiscard where

import qualified Parun.Codec.AnyNumberMatching as AnyNumberMatching
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.AnyNumberDiscard as AnyNumberDiscard

-- | A bare object keyed by the record's field names, Parun.Codec.CountedDiscard's
-- shape: the tag is Parun.Codec.Discard's, and the bound slot is ELIDED when
-- absent.
codec :: Codec.Codec AnyNumberDiscard.AnyNumberDiscard
codec = Fields.object $ do
  player <- Fields.required "player" PlayerRef.codec AnyNumberDiscard.player
  cards <- Fields.required "cards" AnyNumberMatching.codec AnyNumberDiscard.cards
  discarded <- Fields.defaulted "discarded" Nothing (Common.maybe SlotName.codec) AnyNumberDiscard.discarded
  pure
    AnyNumberDiscard.MkAnyNumberDiscard
      { AnyNumberDiscard.player = player,
        AnyNumberDiscard.cards = cards,
        AnyNumberDiscard.discarded = discarded
      }
