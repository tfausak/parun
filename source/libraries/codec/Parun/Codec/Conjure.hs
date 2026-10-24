{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Conjure where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.ConjureCards as ConjureCards
import qualified Parun.Codec.ConjureDestination as ConjureDestination
import qualified Parun.Codec.ConjureSelection as ConjureSelection
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Conjure as Conjure

-- | The card codec is a PARAMETER, Parun.Codec.Create's posture: this arm is
-- where card data nests inside card data, and Parun.Codec.Card is what ties the
-- knot.
--
-- One required "cards" key rather than a "card" and an optional "spellbook"
-- beside it, Parun.Types.Conjure's reason: a card the sentence names outright is
-- the one-candidate list, so the two shapes are one key and no card file can
-- write both or neither. A duplicate is a THIRD shape under the same key rather
-- than a key of its own, Parun.Types.ConjureCards's reason: no printing says both
-- and none says neither.
--
-- The count is ELIDED at one, Parun.Codec.CreateCopy's posture rather than
-- Parun.Codec.Create's required key: "conjure a card named Ornithopter" prints no
-- number, so a card writing @1@ would be spelling out something the sentence
-- does not say. The selection is elided the same way and for the same reason:
-- a card naming its card outright asks neither question. The destination has no
-- default to elide to -- every conjuring card states where the card goes.
codec :: (Typeable.Typeable card) => Codec.Codec card -> Codec.Codec (Conjure.Conjure card)
codec cardCodec = Fields.object $ do
  quantity <- Fields.defaulted "quantity" Conjure.defaultQuantity Quantity.codec Conjure.quantity
  cards <- Fields.required "cards" (ConjureCards.codec cardCodec) Conjure.cards
  selection <- Fields.defaulted "selection" Conjure.defaultSelection ConjureSelection.codec Conjure.selection
  destination <- Fields.required "destination" ConjureDestination.codec Conjure.destination
  slot <- Fields.defaulted "slot" Nothing (Common.maybe SlotName.codec) Conjure.slot
  pure
    Conjure.MkConjure
      { Conjure.quantity = quantity,
        Conjure.cards = cards,
        Conjure.selection = selection,
        Conjure.destination = destination,
        Conjure.slot = slot
      }
