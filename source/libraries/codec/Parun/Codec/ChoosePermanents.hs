{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ChoosePermanents where

import qualified Parun.Codec.ChosenPermanents as ChosenPermanents
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ChoosePermanents as ChoosePermanents

-- | A bare object keyed by the record's field names, Parun.Codec.AnyNumberDiscard's
-- shape.
codec :: Codec.Codec ChoosePermanents.ChoosePermanents
codec = Fields.object $ do
  permanents <- Fields.required "permanents" ChosenPermanents.codec ChoosePermanents.permanents
  slot <- Fields.required "slot" SlotName.codec ChoosePermanents.slot
  pileChooser <- Fields.defaulted "pileChooser" Nothing (Common.maybe PlayerRef.codec) ChoosePermanents.pileChooser
  pure
    ChoosePermanents.MkChoosePermanents
      { ChoosePermanents.permanents = permanents,
        ChoosePermanents.slot = slot,
        ChoosePermanents.pileChooser = pileChooser
      }
