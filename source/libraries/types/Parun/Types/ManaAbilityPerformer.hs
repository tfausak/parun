module Parun.Types.ManaAbilityPerformer where

import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Numeric.Natural as Natural
import qualified Parun.Types.Card as Card
import qualified Parun.Types.ClauseIndex as ClauseIndex
import qualified Parun.Types.Effect as Effect
import qualified Parun.Types.Game as Game
import qualified Parun.Types.GrantedAbility as GrantedAbility
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PayGate as PayGate
import qualified Parun.Types.PendingTrigger as PendingTrigger
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.Recipient as Recipient
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.Throw as Throw

-- | CR 405.6c: how the closed half runs the NON-MANA effects of a mana ability
-- -- the ability's source, its controller, and the effects themselves. CR 605.3b
-- gives such an ability no stack object, so nothing above resolves it and the
-- payment path has to run it where it stands.
--
-- A PARAMETER rather than an import because Parun.Engine.Resolve sits ABOVE
-- Parun.Engine.Cost in the module graph, so importing back would close a cycle.
-- Resolve.resolveSpellWith takes its subgame runner and Parun.Engine.Mulligan its
-- hand-action performer the same way (Parun.Types.HandActionPerformer).
--
-- Built by Parun.Engine.Resolve.Effect.performManaAbility around CR 729.1a's
-- subgame runner, which a triggered mana ability can need (CR 605.4a);
-- Parun.Engine.Engine.performManaAbility is the live loop's, and every module
-- below the loop takes the record or the runner as a parameter.
--
-- Deliberately has NO default: "no performer" is not a real state of the world,
-- and one would silently drop the damage Ancient Tomb charges for its mana at
-- whichever call site forgot it.
--
-- A RECORD rather than one function, so that CR 605.4a's triggered mana ability,
-- CR 118.12's resolution cost and CR 706's roll for a cost's coin flip ride the
-- same injection: the payment path needs them too, and all live in
-- Parun.Engine.Resolve, so a parameter of each own would have to be threaded
-- through every caller of Parun.Engine.Cost.pay for no gain.
data ManaAbilityPerformer = MkManaAbilityPerformer
  { -- | CR 405.6c / 608.2c: the ability's source, its controller, the slots
    -- its earlier clauses bound, and the non-mana effects to run; answers those
    -- slots with the ones these effects bound added.
    effects :: ObjectId.ObjectId -> PlayerId.PlayerId -> Map.Map SlotName.SlotName (Set.Set Recipient.Recipient) -> [Effect.Effect Card.Card (GrantedAbility.GrantedAbility Card.Card)] -> Game.Game (Map.Map SlotName.SlotName (Set.Set Recipient.Recipient)),
    -- | CR 605.4a: apply one triggered mana ability where it stands, without
    -- putting it on the stack. Parun.Engine.Cost.tapForManaWith gathers and
    -- classifies (Parun.Engine.ManaAbility.isTriggeredManaAbility); this runs the
    -- ability's effects.
    triggered :: PendingTrigger.PendingTrigger -> Game.Game (),
    -- | CR 118.12: offer one clause's resolution cost -- the source, its
    -- controller, the clause's ordinal and gate, and the answers already
    -- recorded by ordinal (PayGate.offeredAt) -- and say whether the clause
    -- happens. Rhystic Cave's "unless any player pays {1}".
    payGate :: ObjectId.ObjectId -> PlayerId.PlayerId -> ClauseIndex.ClauseIndex -> PayGate.PayGate -> Map.Map ClauseIndex.ClauseIndex (Map.Map PlayerId.PlayerId Bool) -> Game.Game (Bool, Map.Map ClauseIndex.ClauseIndex (Map.Map PlayerId.PlayerId Bool)),
    -- | CR 614.6 / 706.1: throw and record the die roll Pokey, the Scallywagg
    -- makes instead of a cost's coin flip, answering the kept results.
    throwForCoin :: Throw.Throw -> Game.Game [Natural.Natural]
  }
