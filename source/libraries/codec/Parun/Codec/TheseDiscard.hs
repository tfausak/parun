{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.TheseDiscard where

import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.TheseDiscard as TheseDiscard

-- | A bare object keyed by the record's field names, Parun.Codec.CountedDiscard's
-- shape: the tag is Parun.Codec.Discard's, and the bound slot is ELIDED when
-- absent.
codec :: Codec.Codec TheseDiscard.TheseDiscard
codec = Fields.object $ do
  cards <- Fields.required "cards" ObjectRef.codec TheseDiscard.cards
  discarded <- Fields.defaulted "discarded" Nothing (Common.maybe SlotName.codec) TheseDiscard.discarded
  pure
    TheseDiscard.MkTheseDiscard
      { TheseDiscard.cards = cards,
        TheseDiscard.discarded = discarded
      }
