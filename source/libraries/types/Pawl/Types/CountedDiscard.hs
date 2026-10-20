module Pawl.Types.CountedDiscard where

import qualified Pawl.Types.PlayerRef as PlayerRef
import qualified Pawl.Types.Quantity as Quantity
import qualified Pawl.Types.SlotName as SlotName

-- | CR 701.9b's discard: EVERY player the reference names discards this many
-- cards, each choosing their own, in CR 101.4's order. Mind Rot's "target player
-- discards two cards" at one seat; Tinybones Joins Up's "any number of target
-- players each discard a card" and Noxious Toad's "each opponent discards a
-- card" at several.
--
-- A PlayerRef, Pawl.Types.AnyNumberDiscard's `player`: "each opponent" is no
-- slot a card can declare.
data CountedDiscard = MkCountedDiscard
  { player :: PlayerRef.PlayerRef,
    quantity :: Quantity.Quantity,
    -- | Where the CARDS this discard moved are written, for a later effect of the
    -- same resolution to look back at -- Psychic Miasma's "if a land card is
    -- discarded this way", which is CR 701.70a's "if you discarded a nonland card
    -- this way" read from the other side. Pawl.Types.Destroy's `buried` is the
    -- shape and the precedent.
    --
    -- The CR 400.7 incarnations the discard funnel MINTED, never the cards that
    -- were in the hand: rule 701.9a moves the card, and CR 400.7 gives what
    -- arrives a fresh id, so a slot holding the hand id would name an object no
    -- reader of the destination zone can see.
    --
    -- Bound wherever the card wound up rather than only in a graveyard: CR
    -- 701.9a's move happened whatever CR 614 replaced its destination with, and
    -- CR 400.7j is what decides whether a later part of the effect can then FIND
    -- it -- a public destination yes, a hidden one no. That is a question about
    -- the reader, not about this slot.
    --
    -- Pawl.Types.Scope's OverBound is the reader that asks it: a Count over this
    -- slot folds the incarnations themselves, so a discard redirected into
    -- another public zone still answers, where a Count over one ZONE filtered by
    -- Filter.IsBound sees nothing. Pawl.ZoneChangeSpec's Psychic Miasma leg
    -- under Rest in Peace is what proves it.
    --
    -- Absent for a discard nothing looks back at.
    discarded :: Maybe SlotName.SlotName
  }
  deriving (Eq, Ord, Show)
