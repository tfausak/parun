{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.CostBasis where

import qualified Parun.Codec.ManaCost as ManaCost
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.CostBasis as CostBasis
import qualified Parun.Types.ManaCost as ManaCost.Type

-- | A bare object keyed by the record's field names.
--
-- The slot is REQUIRED -- a basis naming no object describes no cost. The
-- reduction is elided when there is none, the empty ManaCost being {0} (CR
-- 118.5); Flash is the one card in `data/cards/` that writes it.
codec :: Codec.Codec CostBasis.CostBasis
codec = Fields.object $ do
  slot <- Fields.required "slot" SlotName.codec CostBasis.slot
  reducedBy <- Fields.defaulted "reducedBy" (ManaCost.Type.MkManaCost []) ManaCost.codec CostBasis.reducedBy
  pure
    CostBasis.MkCostBasis
      { CostBasis.slot = slot,
        CostBasis.reducedBy = reducedBy
      }
