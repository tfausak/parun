{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Create where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.EntryRiders as EntryRiders
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Create as Create
import qualified Parun.Types.EntryRiders as EntryRiders
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation

-- | A bare object keyed by the record's field names, replacing the positional
-- payload this arm used to write.
--
-- That payload was FOUR shapes: two, three or four elements, and the
-- three-element form was itself two shapes told apart by JSON TYPE, since a slot
-- name is a string and riders are an object. Independently elided keys say all
-- of it with nothing to disambiguate, and CR 111.2's creator joined them as a
-- third.
--
-- The card codec is a PARAMETER, the posture Parun.Codec.Filter takes with its
-- keyword: this arm is where card data nests inside card data, and
-- Parun.Codec.Card is what ties the knot.
codec :: (Typeable.Typeable card, Typeable.Typeable ability, Eq ability) => Codec.Codec card -> Codec.Codec ability -> Codec.Codec (Create.Create card ability)
codec cardCodec abilityCodec = Fields.object $ do
  quantity <- Fields.required "quantity" Quantity.codec Create.quantity
  card <- Fields.required "card" cardCodec Create.card
  riders <- Fields.defaulted "riders" EntryRiders.defaultValue (EntryRiders.codec abilityCodec) Create.riders
  slot <- Fields.defaulted "slot" Nothing (Common.maybe SlotName.codec) Create.slot
  -- CR 111.2 under CR 109.5: elided is "you", which is all but one printing.
  creator <- Fields.defaulted "creator" (PlayerRef.Relative PlayerRelation.You) PlayerRef.codec Create.creator
  pure
    Create.MkCreate
      { Create.quantity = quantity,
        Create.card = card,
        Create.riders = riders,
        Create.slot = slot,
        Create.creator = creator
      }
