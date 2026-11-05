module Parun.Types.LeavesZoneTrigger where

import qualified Parun.Types.ActingPermanent as ActingPermanent
import qualified Parun.Types.Batching as Batching
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.TurnScope as TurnScope
import qualified Parun.Types.Zone as Zone

-- | CR 400.7: a card leaving a zone other than the battlefield -- which card,
-- from and to where, whose pile, on whose turns, and per card or per batch
-- (CR 603.2c). Kishla Skimmer's "whenever a card leaves your graveyard during
-- your turn", Spirit Mascot's "one or more cards", Oglor, Devoted Assistant's
-- grant's "when this card leaves your graveyard".
--
-- A Matching card's Filter reads the card that LEFT (CR 608.2h); the turn is no
-- characteristic of any object and comes from the game state.
data LeavesZoneTrigger = MkLeavesZoneTrigger
  { card :: ActingPermanent.ActingPermanent,
    -- | The zone the card left (CR 400.7).
    from :: Zone.Zone,
    -- | The zone it went to, where the printing names one; Nothing admits any.
    to :: Maybe Zone.Zone,
    -- | CR 400.1: whose library, hand or graveyard the card left, relative to
    -- the ability's controller, read off the pile it left (LastKnown.pile).
    -- Nothing admits any player's.
    whose :: Maybe PlayerRelation.PlayerRelation,
    scope :: TurnScope.TurnScope,
    batching :: Batching.Batching
  }
  deriving (Eq, Ord, Show)

-- | "When this card leaves [a zone]": the source, to anywhere, any pile, each
-- turn, once per card. The codec's defaults but the required origin.
self :: Zone.Zone -> LeavesZoneTrigger
self zone =
  MkLeavesZoneTrigger
    { card = ActingPermanent.Self,
      from = zone,
      to = Nothing,
      whose = Nothing,
      scope = TurnScope.PlayersTurn (PlayerRef.Relative PlayerRelation.AnyPlayer),
      batching = Batching.EachOccurrence
    }
