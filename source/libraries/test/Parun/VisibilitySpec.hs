{-# LANGUAGE GADTs #-}

-- Covers Parun.Engine.Visibility. Its other arms are proven by the scenarios
-- under data/scenarios/visibility; this holds the one no priority point reaches,
-- and the stored-grant term pinned on its own.
module Parun.VisibilitySpec where

import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.List as List
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map as Map
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Parun.Engine.Activate as Activate
import qualified Parun.Engine.Engine as Engine
import qualified Parun.Engine.Event as Event
import qualified Parun.Engine.Game as Game
import qualified Parun.Engine.Resolve.Common as Resolve
import qualified Parun.Engine.Setup as Setup
import qualified Parun.Engine.Stack as Stack
import qualified Parun.Engine.Visibility as Visibility
import qualified Parun.Registry as Registry
import qualified Parun.Spec as Spec
import qualified Parun.Support as S
import qualified Parun.Types.AffectedPlayers as AffectedPlayers
import qualified Parun.Types.Asked as Asked
import qualified Parun.Types.Audience as Audience
import qualified Parun.Types.Ballot as Ballot
import qualified Parun.Types.BallotChoice as BallotChoice
import qualified Parun.Types.CandidateCost as CandidateCost
import qualified Parun.Types.Cost as Cost.Type
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.Expiry as Expiry
import qualified Parun.Types.Face as Face
import qualified Parun.Types.GameEvent as GameEvent
import qualified Parun.Types.GameState as GameState
import qualified Parun.Types.Label as Label
import qualified Parun.Types.LoggedEvent as LoggedEvent
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.OptionalDecision as OptionalDecision
import qualified Parun.Types.Phase as Phase
import qualified Parun.Types.PlayerEffect as PlayerEffect
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.PlayerScope as PlayerScope
import qualified Parun.Types.Prompt as Prompt
import qualified Parun.Types.Recipient as Recipient
import qualified Parun.Types.Seat as Seat
import qualified Parun.Types.ShownCards as ShownCards
import qualified Parun.Types.Shows as Shows
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.Staged as Staged
import qualified Parun.Types.Visibility as Visibility.Type
import qualified Parun.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
spec s registry = Spec.describe s "Parun.Engine.Visibility" $ do
  twoBeholdsSpec s registry
  miracleBeforePlacementSpec s registry
  shuffledRevealSpec s registry
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
            | Just cost <- List.find (not . null . Cost.Type.components . CandidateCost.cost) candidates -> cost
          Prompt.ChooseTargets _ _ _ asked -> fmap (\(_, legal) -> Set.filter ((== Just victimId) . Recipient.objectOf) legal) asked
          _ -> S.identityAnswer p
        cast = S.runPure beholding (S.runPure beholding ready (S.cast S.alice firstId)) (S.cast S.alice secondId)
        secondResolved = S.runPure beholding cast Stack.resolveTop
        bothResolved = S.runPure beholding secondResolved Stack.resolveTop
    Spec.assertEqWith s "CR 701.20a with the first Exhale still waiting, bob sees the Dragon card" (Visibility.sees S.bob dragonId secondResolved) Visibility.Type.Visible
    Spec.assertEqWith s "one Exhale is left on the stack" (length (GameState.stack secondResolved)) 1
    Spec.assertEqWith s "CR 701.20a and once it resolves too, he does not" (Visibility.sees S.bob dragonId bothResolved) Visibility.Type.Obscured
    Spec.assertEqWith s "off the same board: both were cast, and both resolved" (GameState.stack bothResolved) []

-- CR 701.20a: a card whose reveal causes an ability to trigger is revealed from
-- the reveal, not from that ability's placement. Vision Skeins {1}{U} Instant,
-- "Each player draws two cards."; Thunderous Wrath {4}{R}{R} Instant, "deals 5
-- damage to any target. Miracle {R}"; Teferi, Hero of Dominaria's emblem,
-- "Whenever you draw a card, exile target permanent an opponent controls."
-- (Oracle checked against Scryfall 2026-10-16.) In alice's turn her Skeins has
-- bob draw the Wrath as his first card of the turn, and he reveals it; alice's
-- two emblem triggers are put on the stack ahead of his miracle trigger (CR
-- 603.3b), so their targets are chosen while his is still waiting. The pair
-- differs in bob's answer to the miracle offer alone.
miracleBeforePlacementSpec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
miracleBeforePlacementSpec s registry = do
  let board revealing = do
        island <- S.printingOf s registry "Island"
        teferi <- S.printingOf s registry "Teferi, Hero of Dominaria"
        skeins <- S.printingOf s registry "Vision Skeins"
        wrath <- S.printingOf s registry "Thunderous Wrath"
        piker <- S.printingOf s registry "Goblin Piker"
        minusEight <- case Face.activatedAbilities (S.combinedFace teferi) of
          [_, _, ability] -> pure ability
          _ -> Spec.assertFailure s "Teferi has three loyalty abilities"
        let base = S.landsFor island S.alice 2 (Setup.emptyGame S.bothPlayers)
            (teferiId, withTeferi) = S.addPermanent teferi S.alice base
            (skeinsId, withSkeins) = S.addHandCard skeins S.alice (S.addCounter CounterKind.Loyalty 8 teferiId withTeferi)
            (_, withPiker) = S.addPermanent piker S.bob withSkeins
            (_, withPikers) = S.addPermanent piker S.bob withPiker
            stocked = List.foldl' (\g owner -> snd (S.addLibraryCard piker owner g)) withPikers [S.alice, S.alice, S.alice, S.bob, S.bob, S.bob]
            -- Added last, so on top.
            (_, withWrath) = S.addLibraryCard wrath S.bob stocked
            ready = withWrath {GameState.phase = Phase.PrecombatMain, GameState.activePlayer = S.alice, GameState.priority = Just S.alice}
            isWrath g oid = fmap S.nameOf (Game.cardOf oid g) == Just (S.printingName wrath)
            -- At each of alice's target prompts, what she sees of bob's Wrath.
            answer :: Asked.Asked r -> State.State [Visibility.Type.Visibility] r
            answer asked = case Asked.prompt asked of
              Prompt.OfferedMiracleReveal {} -> pure (if revealing then OptionalDecision.Exercises else OptionalDecision.Declines)
              p@(Prompt.ChooseTargets _ pid _ _) | pid == S.alice -> do
                let g = Asked.game asked
                State.modify (<> fmap (\oid -> Visibility.sees S.alice oid g) (filter (isWrath g) (Game.zoneMembers Zone.Hand S.bob g)))
                pure (S.identityAnswer p)
              p -> pure (S.identityAnswer p)
            program = do
              Activate.activateAbility S.alice teferiId minusEight
              Stack.resolveTop
              S.cast S.alice skeinsId
              Stack.resolveTop
              Engine.settleForPriority
        pure (State.runState (Engine.runGameAsked answer ready program) [])
  Spec.it s "CR 701.20a a miracle card is revealed while an earlier-placed trigger chooses its targets" $ do
    ((_, after), seen) <- board True
    Spec.assertEqWith s "CR 701.20a at both of alice's target prompts, she sees bob's revealed Wrath" seen [Visibility.Type.Visible, Visibility.Type.Visible]
    Spec.assertEqWith s "CR 603.3b both emblem triggers went under bob's miracle trigger" (length (GameState.stack after)) 3
  Spec.it s "CR 400.2 the same Wrath unrevealed is hidden from alice at those prompts" $ do
    ((_, after), seen) <- board False
    Spec.assertEqWith s "CR 400.2 at both of alice's target prompts, bob's Wrath is hidden from her" seen [Visibility.Type.Obscured, Visibility.Type.Obscured]
    Spec.assertEqWith s "off the same board: only the two emblem triggers were put on the stack" (length (GameState.stack after)) 2

-- CR 701.20d's shuffle, read inside the resolution that revealed the card --
-- the window CR 701.20a keeps open while the spell resolves. No printing reads
-- that window after its shuffle: a card that reveals a library card it leaves
-- there either shuffles last (Grim Reminder, Prophecy), moves the card first
-- (Gifts Ungiven), or leaves it out of the shuffle (CR 701.24b, Mystical
-- Tutor's "shuffle and put that card on top"). Scryfall o:/reveal(s)? (it|them|that card|those cards)[^\n]*shuffle[^\n]*\. [A-Z][^\n]+/,
-- 2026-10-16, no hit that leaves the card behind. So Synthetic Recounted
-- Reminder ({1}{B} Sorcery, "Search your library for a card and reveal it, then
-- shuffle. Target player discards a card.") prints a question after the
-- shuffle; nothing in the CR forbids such a card.
--
-- The pair is the moment, off one run: what bob, the discarding player, sees of
-- the revealed Hill Giant at the shuffle prompt, before anything is reordered,
-- and at his discard prompt, after. The shuffle answer keeps the Giant on top:
-- shuffled is reordered wherever the card lands. Three seats, so the target and
-- the bystander are different players.
shuffledRevealSpec :: (Monad m) => Spec.Spec m n -> Registry.Registry m -> n ()
shuffledRevealSpec s registry =
  Spec.it s "CR 701.20d a revealed card shuffled into its library is no longer seen before the effect finishes" $ do
    swamp <- S.printingOf s registry "Swamp"
    plains <- S.printingOf s registry "Plains"
    giant <- S.printingOf s registry "Hill Giant"
    recount <- S.printingOf s registry "Synthetic Recounted Reminder"
    let g0 = S.landsFor swamp S.alice 2 S.threePlayerGame
        (spell, g1) = S.addHandCard recount S.alice g0
        (_, g2) = S.addLibraryCard plains S.alice g1
        (_, g3) = S.addLibraryCard plains S.alice g2
        -- Added last, so on top.
        (found, g4) = S.addLibraryCard giant S.alice g3
        (_, g5) = S.addHandCard plains S.bob g4
        (_, ready) = S.addHandCard plains S.bob g5
        giants g = [oid | oid <- Game.zoneMembers Zone.Library S.alice g, fmap S.nameOf (Game.cardOf oid g) == Just (S.printingName giant)]
        note :: String -> GameState.GameState -> State.State [(String, [ObjectId.ObjectId], [Visibility.Type.Visibility])] ()
        note label g = State.modify' (<> [(label, giants g, fmap (\oid -> Visibility.sees S.bob oid g) (giants g))])
        answer :: Asked.Asked r -> State.State [(String, [ObjectId.ObjectId], [Visibility.Type.Visibility])] r
        answer asked = case Asked.prompt asked of
          Prompt.Search _ _ offered _ -> pure (filter (== found) offered)
          p@(Prompt.Shuffle _) -> note "shuffle" (Asked.game asked) >> pure (S.identityAnswer p)
          Prompt.ChooseTargets _ _ _ sets -> pure (S.preferring ((==) (Just S.bob) . Recipient.playerOf) sets)
          p@(Prompt.ChooseDiscard _ pid _ _) | pid == S.bob -> note "discard" (Asked.game asked) >> pure (S.identityAnswer p)
          p -> pure (S.castAnswer p)
        ((_, after), seen) = State.runState (Engine.runGameAsked answer ready (S.cast S.alice spell >> Stack.resolveTop)) []
        at label = lookup label [(l, (ids, views)) | (l, ids, views) <- seen]
    -- THE gameplay reading, and first: after the shuffle, with the spell still
    -- resolving, bob no longer sees the Giant.
    Spec.assertEqWith s "CR 701.20d at bob's discard prompt he does not see the shuffled Giant" (fmap snd (at "discard")) (Just [Visibility.Type.Obscured])
    Spec.assertEqWith s "CR 701.20d the shuffled Giant is a new object" (fmap ((== [found]) . fst) (at "discard")) (Just False)
    -- The control, off the same run: before the shuffle, bob saw it.
    Spec.assertEqWith s "CR 701.20a at the shuffle prompt bob sees the revealed Giant" (at "shuffle") (Just ([found], [Visibility.Type.Visible]))
    Spec.assertEqWith s "bob discarded a card" (length (Game.zoneMembers Zone.Graveyard S.bob after)) 1

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
