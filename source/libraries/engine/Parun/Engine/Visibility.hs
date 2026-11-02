-- | What one player may see of one object (CR 400.2). The one place that asks;
-- each later source of visibility joins as a term of sees.
module Parun.Engine.Visibility where

import qualified Data.Map as Map
import qualified Data.Set as Set
import qualified Parun.Engine.Conspiracy as Conspiracy
import qualified Parun.Engine.Decide as Decide
import qualified Parun.Engine.Exile as Exile
import qualified Parun.Engine.Game as Game
import qualified Parun.Engine.PlayerEffect as PlayerEffect
import qualified Parun.Engine.Projection.View as View
import qualified Parun.Types.Audience as Audience
import qualified Parun.Types.BeginningStep as BeginningStep
import qualified Parun.Types.Decider as Decider
import qualified Parun.Types.Facing as Facing
import qualified Parun.Types.GameEvent as GameEvent
import qualified Parun.Types.GameState as GameState
import qualified Parun.Types.LoggedEvent as LoggedEvent
import qualified Parun.Types.Looked as Looked
import qualified Parun.Types.Moved as Moved
import qualified Parun.Types.Object as Object
import Parun.Types.ObjectId (ObjectId)
import qualified Parun.Types.Phase as Phase
import Parun.Types.PlayerId (PlayerId)
import qualified Parun.Types.RevealWindow as RevealWindow
import qualified Parun.Types.ShownCards as ShownCards
import qualified Parun.Types.Shows as Shows
import qualified Parun.Types.Visibility as Visibility
import qualified Parun.Types.Voted as Voted
import qualified Parun.Types.Zone as Zone
import qualified Parun.Types.ZoneChange as ZoneChange

-- | Whether a player may see an object's face now. CR 723.4: for an object in
-- the game, a player also sees what each player they control sees; a card
-- outside the game (CR 400.11) is seen by its owner alone, never through
-- control.
sees :: PlayerId -> ObjectId -> GameState.GameState -> Visibility.Visibility
sees pid oid gs =
  revealedNow oid gs <> case Game.zoneOf oid gs of
    Nothing -> base pid oid gs
    Just _ -> foldMap (\seat -> base seat oid gs) (pid : controlledBy pid gs)

-- | CR 701.20a: a revealed card is seen by every player while any of its
-- windows is live.
revealedNow :: ObjectId -> GameState.GameState -> Visibility.Visibility
revealedNow oid gs =
  let begun logged = case LoggedEvent.event logged of
        GameEvent.StepBegan _ -> True
        _ -> False
      live window = case window of
        RevealWindow.WhileOnStack sid -> Game.zoneOf sid gs == Just Zone.Stack -- CR 701.20a
        RevealWindow.UntilPriority -> True -- CR 701.20a, until Engine.performSettle closes it
        RevealWindow.UntilFirstTurn -> GameState.turnNumber gs == 1 && not (any begun (GameState.events gs)) -- CR 103.6b
        RevealWindow.DuringUpkeep turn -> GameState.turnNumber gs == turn && GameState.phase gs == Phase.Beginning BeginningStep.Upkeep -- CR 702.57b
   in visibleIf (any (any live . Object.revealed) (Game.lookupObject oid gs))

-- | Whether a player saw what a logged event showed: everyone sees a reveal
-- (CR 701.20a), only its audience a look (CR 701.20e, 723.4) or a ballot (CR
-- 701.38a), and everyone a secret vote's ballots once revealed. An event in
-- the open (CR 400.2) is seen by everyone: a draw as the act alone (CR 121.1),
-- and a move only when everyone saw the card leave (CR 603.10a) or arrive.
witnessed :: PlayerId -> LoggedEvent.LoggedEvent -> Visibility.Visibility
witnessed pid logged = case LoggedEvent.event logged of
  GameEvent.Revealed _ -> Visibility.Visible
  GameEvent.Looked looked -> visibleIf (Set.member pid (Looked.audience looked))
  GameEvent.Voted voted -> visibleIf (Set.member pid (Voted.audience voted))
  GameEvent.VotesRevealed _ -> Visibility.Visible
  GameEvent.Moved moved -> visibleIf (Moved.revealed moved || Moved.seenArriving moved)
  GameEvent.CardArrived change -> visibleIf (not (Game.isHiddenZone (ZoneChange.to change)))
  GameEvent.DamageDealt {} -> Visibility.Visible
  GameEvent.DamagePrevented {} -> Visibility.Visible
  GameEvent.StepBegan {} -> Visibility.Visible
  GameEvent.SpellCast {} -> Visibility.Visible -- CR 601.2a, 708.4: as it is on the stack
  GameEvent.SpellCopied {} -> Visibility.Visible
  GameEvent.BecameMonarch {} -> Visibility.Visible
  GameEvent.TookInitiative {} -> Visibility.Visible
  GameEvent.Discarded {} -> Visibility.Visible
  GameEvent.Milled {} -> Visibility.Visible
  GameEvent.Drew {} -> Visibility.Visible
  GameEvent.AttackerDeclared {} -> Visibility.Visible
  GameEvent.BecameAttacked {} -> Visibility.Visible
  GameEvent.AttackersDeclared {} -> Visibility.Visible
  GameEvent.BecameBlocking {} -> Visibility.Visible
  GameEvent.AttackerBlocked {} -> Visibility.Visible
  GameEvent.AttackerUnblocked {} -> Visibility.Visible
  GameEvent.BlocksDeclared {} -> Visibility.Visible
  GameEvent.SpellCountered {} -> Visibility.Visible
  GameEvent.AbilityCountered {} -> Visibility.Visible
  GameEvent.LifeLost {} -> Visibility.Visible
  GameEvent.LifeGained {} -> Visibility.Visible
  GameEvent.AbilityActivated {} -> Visibility.Visible
  GameEvent.CountersPut {} -> Visibility.Visible
  GameEvent.CountersRemoved {} -> Visibility.Visible
  GameEvent.HalfUnlocked {} -> Visibility.Visible
  GameEvent.TurnedFaceUp {} -> Visibility.Visible
  GameEvent.Transformed {} -> Visibility.Visible
  GameEvent.BecameDesignated {} -> Visibility.Visible
  GameEvent.Mentored {} -> Visibility.Visible
  GameEvent.Exploited {} -> Visibility.Visible
  GameEvent.Convoked {} -> Visibility.Visible
  GameEvent.Crewed {} -> Visibility.Visible
  GameEvent.BecameCrewed {} -> Visibility.Visible
  GameEvent.Saddled {} -> Visibility.Visible
  GameEvent.PermanentSacrificed {} -> Visibility.Visible
  GameEvent.AbilityTriggered {} -> Visibility.Visible -- CR 603.3: it goes on the stack
  GameEvent.ControlChanged {} -> Visibility.Visible
  GameEvent.VentureMarkerEntered {} -> Visibility.Visible
  GameEvent.BecameTarget {} -> Visibility.Visible
  GameEvent.BecameAttached {} -> Visibility.Visible
  GameEvent.BecameUnattached {} -> Visibility.Visible
  GameEvent.LeftTheGame {} -> Visibility.Visible
  GameEvent.LostTheGame {} -> Visibility.Visible
  GameEvent.LandPlayed {} -> Visibility.Visible
  GameEvent.ManifestedDread {} -> Visibility.Visible
  GameEvent.DieResultSettled {} -> Visibility.Visible
  GameEvent.RolledToVisit {} -> Visibility.Visible
  GameEvent.PlanarDieRolled {} -> Visibility.Visible
  GameEvent.TurnedUpOffDeck {} -> Visibility.Visible
  GameEvent.ChaosEnsued -> Visibility.Visible
  GameEvent.ClassLevelSet {} -> Visibility.Visible
  GameEvent.Plotted {} -> Visibility.Visible
  GameEvent.BecameTapped {} -> Visibility.Visible
  GameEvent.BecameUntapped {} -> Visibility.Visible
  GameEvent.TappedForMana {} -> Visibility.Visible
  GameEvent.ManaAdded {} -> Visibility.Visible
  GameEvent.ManaAbilityResolved {} -> Visibility.Visible
  GameEvent.CoinFlipped {} -> Visibility.Visible
  GameEvent.ActivatedAbilityResolved {} -> Visibility.Visible -- CR 602.2a: one from a hidden zone reveals its card
  GameEvent.TriggeredAbilityResolved {} -> Visibility.Visible
  GameEvent.PermanentActed {} -> Visibility.Visible
  GameEvent.PlayerActed {} -> Visibility.Visible
  GameEvent.StickerPut {} -> Visibility.Visible

-- | CR 400.2: whether every player still in the game may see an object's face
-- now.
seenByEveryone :: ObjectId -> GameState.GameState -> Bool
seenByEveryone oid gs = all (\seat -> sees seat oid gs == Visibility.Visible) (Game.stillPlaying gs)

-- | CR 723.5: the players whose decisions this player makes, by the reading
-- Parun.Engine.Decide.deciderFor makes, so a dormant row waiting for its spell
-- (CR 723.2) or one overwritten by a later control (CR 723.1a) lends no sight.
controlledBy :: PlayerId -> GameState.GameState -> [PlayerId]
controlledBy pid gs =
  [ seat
  | seat <- Map.keys (GameState.control gs),
    seat /= pid,
    Decider.unwrap (Decide.deciderFor seat gs) == pid
  ]

-- One player's own sight, before CR 723.4.
--
-- Not implemented: a card in an Attraction, Contraption, planar or scheme deck is
-- face down (CR 314.6, 701.31b, 701.51b, 729.5a; the Unstable FAQ's Contraption
-- back) but answers here as its facing does (#4990).
base :: PlayerId -> ObjectId -> GameState.GameState -> Visibility.Visibility
base pid oid gs = case Game.lookupObject oid gs of
  Nothing -> Visibility.Obscured
  Just obj -> case Game.zoneOf oid gs of
    Nothing -> visibleIf (Object.owner obj == pid) -- CR 400.11
    -- Not implemented: CR 401.5's new top card, changed while a special action
    -- is taken, is shown at once rather than after (#5003).
    Just Zone.Library -> shownTo pid oid gs -- CR 401.2, 401.5
    Just Zone.Hand ->
      if Game.keptFaceDown oid gs
        then Visibility.Obscured -- CR 121.8, 708.5
        else visibleIf (Object.owner obj == pid) <> shownTo pid oid gs -- CR 400.2
    Just Zone.Exile -> visibleIf (Exile.mayLookAt pid oid gs) -- CR 406.3
    Just zone -> case Object.facing obj of
      Facing.FaceUp -> Visibility.Visible
      Facing.FaceDown _
        | zone == Zone.Battlefield || zone == Zone.Stack -> visibleIf (View.controllerOf oid gs == Just pid) -- CR 708.5
        | Conspiracy.isFaceDownConspiracy oid gs -> visibleIf (View.controllerOf oid gs == Just pid) -- CR 315.7
        | otherwise -> Visibility.Obscured -- CR 708.5

-- | CR 401.5 / 400.2: a player effect showing the owner's hand or top card.
shownTo :: PlayerId -> ObjectId -> GameState.GameState -> Visibility.Visibility
shownTo seat oid gs = case Game.lookupObject oid gs of
  Nothing -> Visibility.Obscured
  Just obj ->
    let owner = Object.owner obj
        isTop = Game.shownTop owner gs == Just oid
        reaches grant = case Shows.to grant of
          Audience.Everyone -> True
          Audience.ThatPlayer -> seat == owner
        covers grant = case (Shows.cards grant, Game.zoneOf oid gs) of
          (ShownCards.Hand, Just Zone.Hand) -> True
          (ShownCards.TopOfLibrary, Just Zone.Library) -> isTop
          _ -> False
     in -- Only the top card of a library can be shown, so skip the grants below it.
        if Game.zoneOf oid gs == Just Zone.Library && not isTop
          then Visibility.Obscured
          else visibleIf (any (\grant -> covers grant && reaches grant) (PlayerEffect.shownGrants owner gs))

visibleIf :: Bool -> Visibility.Visibility
visibleIf seen = if seen then Visibility.Visible else Visibility.Obscured
