{-# LANGUAGE GADTs #-}

-- Covers Pawl.Engine.Visibility. Its other arms are proven by the scenarios
-- under data/scenarios/visibility; this holds the one no priority point reaches,
-- and the stored-grant term pinned on its own.
module Pawl.VisibilitySpec where

import qualified Data.List as List
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map as Map
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Pawl.Engine.Event as Event
import qualified Pawl.Engine.Resolve.Effect as Resolve
import qualified Pawl.Engine.Setup as Setup
import qualified Pawl.Engine.Stack as Stack
import qualified Pawl.Engine.Visibility as Visibility
import qualified Pawl.Registry as Registry
import qualified Pawl.Spec as Spec
import qualified Pawl.Support as S
import qualified Pawl.Types.AffectedPlayers as AffectedPlayers
import qualified Pawl.Types.Audience as Audience
import qualified Pawl.Types.Ballot as Ballot
import qualified Pawl.Types.BallotChoice as BallotChoice
import qualified Pawl.Types.Cost as Cost.Type
import qualified Pawl.Types.Expiry as Expiry
import qualified Pawl.Types.GameEvent as GameEvent
import qualified Pawl.Types.GameState as GameState
import qualified Pawl.Types.Label as Label
import qualified Pawl.Types.LoggedEvent as LoggedEvent
import qualified Pawl.Types.ObjectId as ObjectId
import qualified Pawl.Types.Phase as Phase
import qualified Pawl.Types.PlayerEffect as PlayerEffect
import qualified Pawl.Types.PlayerRelation as PlayerRelation
import qualified Pawl.Types.PlayerScope as PlayerScope
import qualified Pawl.Types.Prompt as Prompt
import qualified Pawl.Types.Recipient as Recipient
import qualified Pawl.Types.Seat as Seat
import qualified Pawl.Types.ShownCards as ShownCards
import qualified Pawl.Types.Shows as Shows
import qualified Pawl.Types.SlotName as SlotName
import qualified Pawl.Types.Staged as Staged
import qualified Pawl.Types.Visibility as Visibility.Type

spec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
spec s registry = Spec.describe s "Pawl.Engine.Visibility" $ do
  twoBeholdsSpec s registry
  -- A card CR 121.8 keeps face down in hand exists only mid-cast, which no
  -- scenario check reaches, so the mark is written onto the state directly.
  Spec.it s "CR 121.8 / 708.5 a card kept face down in hand is hidden from its owner" $ do
    built <- S.buildBoardOrFail s registry (S.board (S.hand S.alice [S.aliased "wrath" (S.cardSetup "Thunderous Wrath")] NonEmpty.:| [S.playerSetup S.bob]) S.alice S.precombatMain)
    wrath <- maybe (Spec.assertFailure s "no wrath") pure (Map.lookup (Label.MkLabel (Text.pack "wrath")) (Staged.objects built))
    let gs = Staged.state built
        kept = gs {GameState.keptFaceDown = Just (Map.singleton wrath 0)}
    Spec.assertEqWith s "the control: unmarked, its owner sees it" (Visibility.sees S.alice wrath gs) Visibility.Type.Visible
    Spec.assertEqWith s "marked by CR 121.8, its owner does not" (Visibility.sees S.alice wrath kept) Visibility.Type.Obscured
  -- The grant is seeded directly, pinning the term apart from any card that
  -- stores one.
  Spec.it s "CR 401.5 / 400.2 a revealed hand is seen by every player" $ do
    (gs, card, _, _) <- shownBoard s registry
    let shown = showing ShownCards.Hand Audience.Everyone gs
    Spec.assertEqWith s "the control: without the grant, bob does not see it" (Visibility.sees S.bob card gs) Visibility.Type.Obscured
    Spec.assertEqWith s "with the hand revealed, bob sees it" (Visibility.sees S.bob card shown) Visibility.Type.Visible
  Spec.it s "CR 121.8 a card kept face down stays hidden in a revealed hand" $ do
    (gs, card, _, _) <- shownBoard s registry
    let kept = (showing ShownCards.Hand Audience.Everyone gs) {GameState.keptFaceDown = Just (Map.singleton card 0)}
    Spec.assertEqWith s "bob does not see the kept card" (Visibility.sees S.bob card kept) Visibility.Type.Obscured
    Spec.assertEqWith s "alice does not see the kept card" (Visibility.sees S.alice card kept) Visibility.Type.Obscured
  Spec.it s "CR 401.5 / 400.2 a look at the top card is the owner's alone" $ do
    (gs, _, top, second) <- shownBoard s registry
    let looked = showing ShownCards.TopOfLibrary Audience.ThatPlayer gs
    Spec.assertEqWith s "the control: without the grant, alice does not see her top card" (Visibility.sees S.alice top gs) Visibility.Type.Obscured
    Spec.assertEqWith s "alice sees her top card" (Visibility.sees S.alice top looked) Visibility.Type.Visible
    Spec.assertEqWith s "bob does not see alice's top card" (Visibility.sees S.bob top looked) Visibility.Type.Obscured
    Spec.assertEqWith s "alice does not see her second card" (Visibility.sees S.alice second looked) Visibility.Type.Obscured
  -- CR 723.4: a scenario reaches this only through Mindslaver and bob's next
  -- turn, so the control row is written onto the state directly and the case
  -- pins the look's audience alone.
  Spec.it s "a look while controlled is witnessed by the controller too" $ do
    let bob = (S.playerSetup S.bob) {Seat.library = Seq.fromList [S.aliased "top" (S.cardSetup "Grizzly Bears")]}
    built <- S.buildBoardOrFail s registry (S.board (S.playerSetup S.alice NonEmpty.:| [bob, S.playerSetup S.carol]) S.alice S.precombatMain)
    top <- maybe (Spec.assertFailure s "no top") pure (Map.lookup (Label.MkLabel (Text.pack "top")) (Staged.objects built))
    let plain = Staged.state built
        controlled = plain {GameState.control = S.turnControl S.alice S.bob}
        lastLogged gs = case Seq.viewr (GameState.events (S.runPure S.identityAnswer gs (Event.look S.bob top))) of
          _ Seq.:> logged -> pure logged
          Seq.EmptyR -> Spec.assertFailure s "no event logged"
    uncontrolledLook <- lastLogged plain
    controlledLook <- lastLogged controlled
    Spec.assertEqWith s "the control: uncontrolled, alice does not witness bob's look" (Visibility.witnessed S.alice uncontrolledLook) Visibility.Type.Obscured
    Spec.assertEqWith s "controlling bob, alice witnesses his look" (Visibility.witnessed S.alice controlledLook) Visibility.Type.Visible
    Spec.assertEqWith s "bob witnesses his own look" (Visibility.witnessed S.bob controlledLook) Visibility.Type.Visible
    Spec.assertEqWith s "carol does not witness it" (Visibility.witnessed S.carol controlledLook) Visibility.Type.Obscured
  -- CR 701.38a / 723.4: the control row is written onto the state directly, as
  -- above, and the ballot logged through the Vote arm's own logger.
  Spec.it s "a secret ballot is witnessed by its voter and the voter's controller" $ do
    built <- S.buildBoardOrFail s registry (S.board (S.playerSetup S.alice NonEmpty.:| [S.playerSetup S.bob, S.playerSetup S.carol]) S.alice S.precombatMain)
    let plain = Staged.state built
        controlled = plain {GameState.control = S.turnControl S.alice S.bob}
        ballot = Ballot.MkBallot S.bob (BallotChoice.ForWord (SlotName.MkSlotName (Text.pack "truth")))
        lastLogged gs = case Seq.viewr (GameState.events (S.runPure S.identityAnswer gs (Resolve.logBallot True ballot))) of
          _ Seq.:> logged -> pure logged
          Seq.EmptyR -> Spec.assertFailure s "no event logged"
    uncontrolledVote <- lastLogged plain
    controlledVote <- lastLogged controlled
    let revealed = controlledVote {LoggedEvent.event = GameEvent.VotesRevealed (Seq.fromList [ballot])}
    Spec.assertEqWith s "the control: uncontrolled, alice does not witness bob's ballot" (Visibility.witnessed S.alice uncontrolledVote) Visibility.Type.Obscured
    Spec.assertEqWith s "controlling bob, alice witnesses his ballot" (Visibility.witnessed S.alice controlledVote) Visibility.Type.Visible
    Spec.assertEqWith s "bob witnesses his own ballot" (Visibility.witnessed S.bob controlledVote) Visibility.Type.Visible
    Spec.assertEqWith s "carol does not witness it" (Visibility.witnessed S.carol controlledVote) Visibility.Type.Obscured
    Spec.assertEqWith s "carol witnesses the reveal" (Visibility.witnessed S.carol revealed) Visibility.Type.Visible
    Spec.assertEqWith s "alice witnesses the reveal" (Visibility.witnessed S.alice revealed) Visibility.Type.Visible
    Spec.assertEqWith s "bob witnesses the reveal" (Visibility.witnessed S.bob revealed) Visibility.Type.Visible
  -- CR 801.2 / 801.11: range of influence limits what a player can affect and
  -- what a spell reads, not what a player sees, so carol, two seats away at
  -- range 1, still sees alice's open ballot.
  Spec.it s "an open ballot is witnessed by every player, in range or not" $ do
    built <- S.buildBoardOrFail s registry (S.board (S.playerSetup S.alice NonEmpty.:| [S.playerSetup S.bob, S.playerSetup S.carol, S.playerSetup S.dave]) S.alice S.precombatMain)
    let ballot = Ballot.MkBallot S.alice (BallotChoice.ForWord (SlotName.MkSlotName (Text.pack "truth")))
    logged <- case Seq.viewr (GameState.events (S.runPure S.identityAnswer (S.withRange 1 (Staged.state built)) (Resolve.logBallot False ballot))) of
      _ Seq.:> entry -> pure entry
      Seq.EmptyR -> Spec.assertFailure s "no event logged"
    Spec.assertEqWith s "carol, out of alice's range, witnesses her open ballot" (Visibility.witnessed S.carol logged) Visibility.Type.Visible

-- CR 701.20a: a card revealed for two reasons stays revealed while either
-- lasts. Caustic Exhale {B} Instant, "As an additional cost to cast this spell,
-- behold a Dragon or pay {1}. Target creature gets -3/-3 until end of turn."
-- (Oracle checked against Scryfall 2026-10-15.) alice casts two, beholding her
-- one Hoarding Dragon card for each, so the card is revealed until the FIRST
-- Exhale leaves the stack, which the second resolving ahead of it must not cut
-- short.
twoBeholdsSpec :: (Monad m) => Spec.Spec m n -> Registry.Registry m -> n ()
twoBeholdsSpec s registry =
  Spec.it s "CR 701.20a a second behold leaves the first one's window standing" $ do
    swamp <- S.printingOf s registry "Swamp"
    exhale <- S.printingOf s registry "Caustic Exhale"
    dragon <- S.printingOf s registry "Hoarding Dragon"
    galleon <- S.printingOf s registry "Armored Galleon"
    let base = S.landsFor swamp S.alice 2 (Setup.emptyGame S.bothPlayers)
        (victimId, withVictim) = S.addPermanent galleon S.bob base
        (dragonId, withDragon) = S.addHandCard dragon S.alice withVictim
        (firstId, withFirst) = S.addHandCard exhale S.alice withDragon
        (secondId, staged) = S.addHandCard exhale S.alice withFirst
        ready = staged {GameState.phase = Phase.PrecombatMain, GameState.activePlayer = S.alice, GameState.priority = Just S.alice}
        -- CR 601.2b's announcement, filtered out of the costs offered: the behold
        -- is the only component either option carries.
        beholding :: Prompt.Prompt r -> r
        beholding p = case p of
          Prompt.ChooseCost _ _ _ candidates
            | Just cost <- List.find (not . null . Cost.Type.components) candidates -> cost
          Prompt.ChooseTargets _ _ _ asked -> fmap (\(_, legal) -> Set.filter ((== Just victimId) . Recipient.objectOf) legal) asked
          _ -> S.identityAnswer p
        cast = S.runPure beholding (S.runPure beholding ready (S.cast S.alice firstId)) (S.cast S.alice secondId)
        secondResolved = S.runPure beholding cast Stack.resolveTop
        bothResolved = S.runPure beholding secondResolved Stack.resolveTop
    Spec.assertEqWith s "CR 701.20a with the first Exhale still waiting, bob sees the Dragon card" (Visibility.sees S.bob dragonId secondResolved) Visibility.Type.Visible
    Spec.assertEqWith s "one Exhale is left on the stack" (length (GameState.stack secondResolved)) 1
    Spec.assertEqWith s "CR 701.20a and once it resolves too, he does not" (Visibility.sees S.bob dragonId bothResolved) Visibility.Type.Obscured
    Spec.assertEqWith s "off the same board: both were cast, and both resolved" (GameState.stack bothResolved) []

-- Alice holds one card and has two in her library; bob has nothing.
shownBoard :: (Monad m) => Spec.Spec m n -> Registry.Registry m -> m (GameState.GameState, ObjectId.ObjectId, ObjectId.ObjectId, ObjectId.ObjectId)
shownBoard s registry = do
  let alice = (S.playerSetup S.alice) {Seat.hand = Seq.fromList [S.aliased "held" (S.cardSetup "Thunderous Wrath")], Seat.library = Seq.fromList [S.aliased "top" (S.cardSetup "Grizzly Bears"), S.aliased "second" (S.cardSetup "Grizzly Bears")]}
  built <- S.buildBoardOrFail s registry (S.board (alice NonEmpty.:| [S.playerSetup S.bob]) S.alice S.precombatMain)
  let labelled name = maybe (Spec.assertFailure s ("no " <> name)) pure (Map.lookup (Label.MkLabel (Text.pack name)) (Staged.objects built))
  held <- labelled "held"
  top <- labelled "top"
  second <- labelled "second"
  pure (Staged.state built, held, top, second)

-- Alice's own grant, stored for the rest of the game.
showing :: ShownCards.ShownCards -> Audience.Audience -> GameState.GameState -> GameState.GameState
showing cards to =
  S.addPlayerEffect Expiry.Never (AffectedPlayers.Scoped (PlayerScope.Related PlayerRelation.You)) (PlayerEffect.Shows (Shows.MkShows cards to)) S.alice
