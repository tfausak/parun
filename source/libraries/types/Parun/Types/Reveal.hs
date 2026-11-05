module Parun.Types.Reveal where

import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.SlotName as SlotName

-- | The payload of Parun.Types.Effect's Reveal arm: WHICH cards CR 701.20a's
-- reveal shows, and the slot -- if any -- the resolution remembers them in.
--
-- Parun.Types.LookAt's shape, minus that type's requirement on the slot. A look's
-- GameEvent.Looked reaches its one audience alone (CR 701.20e), so a later clause
-- reads the cards through LookAt's slot, which is the whole point of the opcode;
-- a reveal is public, so the GameEvent.Revealed it appends is
-- already a record and a slotless reveal is the whole of rule 701.20a. Merfolk
-- Spy writes one; Wild Evocation's "that player reveals a card at random from
-- their hand ... the player casts IT" needs the name, and so does Carth the
-- Lion's "reveal a planeswalker card from among them AND put it into your hand",
-- where the slot is the whole of what keeps the reveal and the move on one card.
--
-- Maybe rather than a second opcode, for the reason #1743 declined a
-- RevealAtRandom: one rule, one arm. A sibling that revealed AND bound would
-- duplicate rule 701.20a over a wider radius -- every consumer that classifies
-- effects would have to learn both.
data Reveal = MkReveal
  { ref :: ObjectRef.ObjectRef,
    slot :: Maybe SlotName.SlotName
  }
  deriving (Eq, Ord, Show)
