{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.CountedDiscard where

import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.CountedDiscard as CountedDiscard

-- | A bare object keyed by the record's field names. The tag that picks it is
-- written by Parun.Codec.Discard's Counted arm.
--
-- The bound slot is ELIDED when absent, Parun.Codec.Destroy's rule, so a card that
-- never looks back at what it discarded writes only the two keys it always did.
codec :: Codec.Codec CountedDiscard.CountedDiscard
codec = Fields.object $ do
  player <- Fields.required "player" PlayerRef.codec CountedDiscard.player
  quantity <- Fields.required "quantity" Quantity.codec CountedDiscard.quantity
  discarded <- Fields.defaulted "discarded" Nothing (Common.maybe SlotName.codec) CountedDiscard.discarded
  pure
    CountedDiscard.MkCountedDiscard
      { CountedDiscard.player = player,
        CountedDiscard.quantity = quantity,
        CountedDiscard.discarded = discarded
      }
