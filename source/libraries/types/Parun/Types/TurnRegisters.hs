module Parun.Types.TurnRegisters where

import qualified Data.Map.Strict as Map
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Numeric.Natural as Natural
import qualified Parun.Types.ActivatedAbility as ActivatedAbility
import qualified Parun.Types.Card as Card
import qualified Parun.Types.CastFromZone as CastFromZone
import qualified Parun.Types.Combat as Combat
import qualified Parun.Types.EndTurnSignal as EndTurnSignal
import qualified Parun.Types.EventGroup as EventGroup
import qualified Parun.Types.GrantedAbility as GrantedAbility
import qualified Parun.Types.LastKnown as LastKnown
import qualified Parun.Types.LoggedEvent as LoggedEvent
import qualified Parun.Types.ModifiedRoll as ModifiedRoll
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PastActivation as PastActivation
import qualified Parun.Types.Phase as Phase
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.Timestamp as Timestamp
import qualified Parun.Types.TurnResume as TurnResume

-- | CR 807.4b / 807.5: a running Grand Melee turn the scheduler is not working,
-- parked on GameState.parkedTurns under its marker's number. Each field is the
-- GameState field of the same name as that turn left it.
data TurnRegisters = MkTurnRegisters
  { activePlayer :: PlayerId.PlayerId,
    phase :: Phase.Phase,
    remaining :: Seq.Seq Phase.Phase,
    -- | CR 807.5: its marker's own stack.
    stack :: [ObjectId.ObjectId],
    stackedIn :: Map.Map ObjectId.ObjectId EventGroup.EventGroup,
    priority :: Maybe PlayerId.PlayerId,
    passed :: Set.Set PlayerId.PlayerId,
    combat :: Combat.Combat,
    events :: Seq.Seq LoggedEvent.LoggedEvent,
    scannedThrough :: Natural.Natural,
    damageScannedThrough :: Natural.Natural,
    turnNumber :: Natural.Natural,
    turnAnchor :: Maybe PlayerId.PlayerId,
    extraTurnUnderWay :: Maybe Timestamp.Timestamp,
    permanentsAsTurnBegan :: Maybe (Map.Map ObjectId.ObjectId LastKnown.LastKnown),
    endTurnSignal :: EndTurnSignal.EndTurnSignal,
    drawsThisTurn :: Map.Map PlayerId.PlayerId (Seq.Seq ObjectId.ObjectId),
    couldAttackThisTurn :: Set.Set ObjectId.ObjectId,
    activatedThisTurn :: Map.Map ObjectId.ObjectId (Map.Map (ActivatedAbility.ActivatedAbility Card.Card (GrantedAbility.GrantedAbility Card.Card)) Natural.Natural),
    activationsThisTurn :: Seq.Seq PastActivation.PastActivation,
    castPermissionsUsedThisTurn :: Map.Map ObjectId.ObjectId (Set.Set CastFromZone.CastFromZone),
    rollModifiersUsedThisTurn :: Map.Map ObjectId.ObjectId (Set.Set ModifiedRoll.ModifiedRoll),
    turnResume :: TurnResume.TurnResume
  }
  deriving (Eq, Ord, Show)
