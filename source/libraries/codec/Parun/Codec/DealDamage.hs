{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.DealDamage where

import qualified Parun.Codec.DamagePart as DamagePart
import qualified Parun.Codec.ExcessDestination as ExcessDestination
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.DealDamage as DealDamage

-- | A bare object keyed by the record's field names. The tag that picks it is
-- written by Parun.Codec.Effect's DealDamage arm.
codec :: Codec.Codec DealDamage.DealDamage
codec = Fields.object $ do
  parts <- Fields.required "parts" (Common.seq DamagePart.codec) DealDamage.parts
  dealer <- Fields.defaulted "dealer" Nothing (Common.maybe SlotName.codec) DealDamage.dealer
  -- Defaulted to Nothing, so every card that deals damage without saying where
  -- the excess goes -- which is every one of them but Flame Spill -- keeps
  -- parsing unchanged.
  excess <- Fields.defaulted "excess" Nothing (Common.maybe ExcessDestination.codec) DealDamage.excess
  tally <- Fields.defaulted "tally" Nothing (Common.maybe SlotName.codec) DealDamage.tally
  damaged <- Fields.defaulted "damaged" Nothing (Common.maybe SlotName.codec) DealDamage.damaged
  pure
    DealDamage.MkDealDamage
      { DealDamage.parts = parts,
        DealDamage.dealer = dealer,
        DealDamage.excess = excess,
        DealDamage.tally = tally,
        DealDamage.damaged = damaged
      }
