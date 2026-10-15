{-# LANGUAGE GADTs #-}
{-# LANGUAGE RankNTypes #-}

-- | CR 901, the Planechase variant: Pawl.Engine.Planechase and Pawl.Engine.Plane,
-- with Pawl.Types.Action's RollPlanarDie, Pawl.Types.TriggerCondition's
-- ChaosEnsues, Pawl.Types.Effect's Planeswalk and ChaosEnsues, and
-- Pawl.Types.ReplacementEffect's PlaneswalkR.
module Pawl.PlanechaseSpec where

import qualified Control.Monad as Monad
import qualified Data.List as List
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Data.Text as Text
import Numeric.Natural (Natural)
import Pawl.CastProhibitionSpec (playEveryLand)
import qualified Pawl.Engine.Action as Action
import qualified Pawl.Engine.CombatRestriction as CombatRestriction
import qualified Pawl.Engine.Cost as Cost
import qualified Pawl.Engine.Engine as Engine
import qualified Pawl.Engine.Event as Event
import qualified Pawl.Engine.Game as Game
import qualified Pawl.Engine.Planechase as Planechase
import qualified Pawl.Engine.PlayerEffect as PlayerEffect
import qualified Pawl.Engine.Projection as Projection
import qualified Pawl.Engine.Projection.View as Projection
import qualified Pawl.Engine.Resolve.Effect as Resolve
import qualified Pawl.Engine.Setup as Setup
import qualified Pawl.Engine.Stack as Stack
import qualified Pawl.Registry as Registry
import qualified Pawl.Spec as Spec
import qualified Pawl.Support as S
import qualified Pawl.Types.Action as Action.Type
import qualified Pawl.Types.CandidateCost as CandidateCost
import qualified Pawl.Types.CardName as CardName
import qualified Pawl.Types.Color as Color
import qualified Pawl.Types.Concession as Concession
import qualified Pawl.Types.Cost as Cost.Type
import qualified Pawl.Types.Deck as Deck
import qualified Pawl.Types.EndingStep as EndingStep
import qualified Pawl.Types.Face as Face
import qualified Pawl.Types.GameEvent as GameEvent
import qualified Pawl.Types.GameState as GameState
import qualified Pawl.Types.InherentTriggerSource as InherentTriggerSource
import qualified Pawl.Types.Keyword as Keyword
import qualified Pawl.Types.ManaCost as ManaCost
import qualified Pawl.Types.ManaSymbol as ManaSymbol
import qualified Pawl.Types.ManaType as ManaType
import qualified Pawl.Types.Object as Object
import qualified Pawl.Types.ObjectId as ObjectId
import qualified Pawl.Types.Phase as Phase
import qualified Pawl.Types.PlayerActed as PlayerActed
import qualified Pawl.Types.PlayerAction as PlayerAction
import qualified Pawl.Types.PlayerId as PlayerId
import qualified Pawl.Types.Prompt as Prompt
import qualified Pawl.Types.Recipient as Recipient
import qualified Pawl.Types.SideDeck as SideDeck
import qualified Pawl.Types.SlotName as SlotName
import qualified Pawl.Types.Source as Source
import qualified Pawl.Types.StepBegan as StepBegan
import qualified Pawl.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
spec s registry = Spec.describe s "Pawl.Engine.Planechase" $ do
  -- CR 103.7 through the whole of Setup.newGame: after the opening hands, the
  -- starting player's top planar card is face up and the rest stay in the deck.
  Spec.it s "CR 103.7 a new game begins with the starting player's top plane face up" $ do
    forest <- S.printingOf s registry "Forest"
    academy <- S.printingOf s registry "Academy at Tolaria West"
    tazeem <- S.printingOf s registry "Tazeem"
    let alices = (Deck.fromCards (Map.singleton forest 20)) {Deck.sideDecks = Map.singleton SideDeck.Planar (Map.fromSet (const 1) (Set.fromList [academy, tazeem]))}
        bobs = Deck.fromCards (Map.singleton forest 20)
        started = S.runPure S.identityAnswer (Setup.emptyGame S.bothPlayers) (Setup.newGame (Resolve.performHandAction Resolve.noSubgame) ((S.alice, alices) NonEmpty.:| [(S.bob, bobs)]))
    Spec.assertEqWith s "one plane is face up" (length (Planechase.faceUp started)) 1
    Spec.assertEqWith s "and the other is still alice's planar deck" (length (Planechase.deckOf S.alice started)) 1
    Spec.assertEqWith s "and neither is in her library" (length (Game.zoneMembers Zone.Library S.alice started)) 13

  -- CR 311.4 / 901.7 and CR 901.6: Academy at Tolaria West ("At the beginning of
  -- your end step, if you have no cards in hand, draw seven cards.") is alice's,
  -- but its controller is the planar controller -- the active player -- so on
  -- bob's turn it is bob who draws.
  Spec.it s "CR 901.6 the face-up plane's end-step trigger is the active player's" $ do
    board <- planarBoard s registry ["Academy at Tolaria West"]
    let alicesEnd = endStep S.alice board
        bobsEnd = endStep S.bob board
    Spec.assertEqWith s "CR 311.4 at alice's end step alice draws seven" (S.handSize S.alice alicesEnd, S.handSize S.bob alicesEnd) (7, 0)
    Spec.assertEqWith s "CR 901.6 at bob's end step bob draws seven, though alice owns the plane" (S.handSize S.alice bobsEnd, S.handSize S.bob bobsEnd) (0, 7)

  -- CR 311.4: a face-up plane's static abilities affect the game. Tazeem's
  -- "Creatures can't block" reaches bob's creature; in the planar deck it does
  -- not.
  Spec.it s "CR 311.4 a face-up Tazeem stops creatures from blocking" $ do
    piker <- S.printingOf s registry "Goblin Piker"
    board <- planarBoard s registry ["Tazeem", "Academy at Tolaria West"]
    buried <- planarBoard s registry ["Academy at Tolaria West", "Tazeem"]
    let (pikerId, withPiker) = S.addPermanent piker S.bob board
        (buriedPiker, withBuried) = S.addPermanent piker S.bob buried
    Spec.assertBool s (Set.member pikerId (CombatRestriction.cantBlock (Just S.bob) [pikerId] withPiker)) "CR 311.4 with Tazeem face up bob's creature can't block"
    Spec.assertBool s (not (Set.member buriedPiker (CombatRestriction.cantBlock (Just S.bob) [buriedPiker] withBuried))) "with Tazeem in the planar deck it can"

  -- CR 801.18 / 901.13: a plane is exempt from the limited range of influence
  -- option. Four seats at range 1, alice the planar controller with Tazeem
  -- ("Creatures can't block") face up, and carol two seats from her. The pair
  -- has Academy at Tolaria West face up instead and alice's Bedlam, printing
  -- the same words on an enchantment, which CR 801.10 keeps from carol's
  -- creature.
  Spec.it s "CR 801.18 a face-up Tazeem stops a creature outside the planar controller's range from blocking" $ do
    piker <- S.printingOf s registry "Goblin Piker"
    bedlam <- S.printingOf s registry "Bedlam"
    planar <- seatedPlanarBoard s registry S.alice [(S.alice, ["Tazeem"]), (S.bob, []), (S.carol, []), (S.dave, [])]
    unplanar <- seatedPlanarBoard s registry S.alice [(S.alice, ["Academy at Tolaria West"]), (S.bob, []), (S.carol, []), (S.dave, [])]
    let (carols, withTazeem) = S.addPermanent piker S.carol planar
        (_, enchanted) = S.addPermanent bedlam S.alice unplanar
        (carolsToo, withBedlam) = S.addPermanent piker S.carol enchanted
    Spec.assertBool s (Set.member carols (CombatRestriction.cantBlock (Just S.carol) [carols] (S.withRange 1 withTazeem))) "CR 801.18 at range 1 carol's creature can't block under Tazeem"
    Spec.assertBool s (not (Set.member carolsToo (CombatRestriction.cantBlock (Just S.carol) [carolsToo] (S.withRange 1 withBedlam)))) "CR 801.10 at range 1 alice's Bedlam does not reach it"
    Spec.assertBool s (Set.member carolsToo (CombatRestriction.cantBlock (Just S.carol) [carolsToo] withBedlam)) "at an unlimited range Bedlam does"
    Spec.assertBool s (not (Game.inRangeOf S.alice S.carol (S.withRange 1 withTazeem))) "carol is outside alice's range"

  -- CR 113.6p / 901.7: a face-up plane's player ability functions from the
  -- command zone. The Lux Foundation Library's "Players have no maximum hand
  -- size" reaches bob; in the planar deck it does not.
  Spec.it s "CR 901.7 a face-up plane's player ability affects the game" $ do
    board <- planarBoard s registry ["The Lux Foundation Library", "Academy at Tolaria West"]
    buried <- planarBoard s registry ["Academy at Tolaria West", "The Lux Foundation Library"]
    Spec.assertEqWith s "CR 901.7 with the Library face up bob has no maximum hand size" (PlayerEffect.maximumHandSize S.bob board) Nothing
    Spec.assertEqWith s "with it in the planar deck his is seven" (PlayerEffect.maximumHandSize S.bob buried) (Just 7)

  -- CR 305.2 / 901.7: Naya's "You may play any number of lands on each of your
  -- turns", face up, lets alice play all five Mountains in her hand; with Naya
  -- in the planar deck CR 305.2's one stands.
  Spec.it s "CR 305.2 a face-up Naya lets the planar controller play any number of lands" $ do
    mountain <- S.printingOf s registry "Mountain"
    board <- planarBoard s registry ["Naya", "Academy at Tolaria West"]
    buried <- planarBoard s registry ["Academy at Tolaria West", "Naya"]
    let withHand gs = inMain S.alice (List.foldl' (\g _ -> snd (S.addHandCard mountain S.alice g)) gs [1 .. 5 :: Int])
        played = playEveryLand (withHand board)
        held = playEveryLand (withHand buried)
    Spec.assertEqWith s "CR 305.2 under Naya all five Mountains landed" (S.countOnBattlefieldByName (S.printingName mountain) S.alice played) 5
    Spec.assertEqWith s "with Naya in the planar deck only one did" (S.countOnBattlefieldByName (S.printingName mountain) S.alice held) 1
    Spec.assertEqWith s "and four are still in her hand" (S.handSize S.alice held) 4

  -- CR 801.18 for a player ability: four seats at range 1, alice the planar
  -- controller with The Lux Foundation Library face up, and carol two seats
  -- from her. The pair has Academy at Tolaria West face up instead and alice's
  -- Price of Knowledge, printing the same words on an enchantment, which CR
  -- 801.10 keeps from carol.
  Spec.it s "CR 801.18 a face-up plane's player ability reaches a player outside the planar controller's range" $ do
    price <- S.printingOf s registry "Price of Knowledge"
    planar <- seatedPlanarBoard s registry S.alice [(S.alice, ["The Lux Foundation Library"]), (S.bob, []), (S.carol, []), (S.dave, [])]
    unplanar <- seatedPlanarBoard s registry S.alice [(S.alice, ["Academy at Tolaria West"]), (S.bob, []), (S.carol, []), (S.dave, [])]
    let (_, enchanted) = S.addPermanent price S.alice unplanar
    Spec.assertEqWith s "CR 801.18 at range 1 carol has no maximum hand size under the Library" (PlayerEffect.maximumHandSize S.carol (S.withRange 1 planar)) Nothing
    Spec.assertEqWith s "CR 801.10 at range 1 alice's Price of Knowledge leaves carol's at seven" (PlayerEffect.maximumHandSize S.carol (S.withRange 1 enchanted)) (Just 7)
    Spec.assertEqWith s "at an unlimited range it reaches her" (PlayerEffect.maximumHandSize S.carol enchanted) Nothing

  -- CR 116.2i / 901.9: the active player, in a main phase with an empty stack,
  -- may roll the planar die; the first roll of the turn is free and the second
  -- costs {1}.
  Spec.it s "CR 901.9 the planar die is the active player's special action, and each roll costs one more" $ do
    forest <- S.printingOf s registry "Forest"
    board <- planarBoard s registry ["Academy at Tolaria West"]
    let main = inMain S.alice board
        rolledOnce = S.runPure (rolling 1) main (Planechase.roll S.manaPerformer S.alice)
        (_, withForest) = S.addPermanent forest S.alice rolledOnce
    Spec.assertBool s (elem Action.Type.RollPlanarDie (Action.legalActions S.alice main)) "CR 116.2i the active player may roll"
    Spec.assertBool s (notElem Action.Type.RollPlanarDie (Action.legalActions S.bob (main {GameState.priority = Just S.bob}))) "and a player whose turn it isn't may not"
    Spec.assertBool s (elem (GameEvent.PlayerActed (PlayerActed.MkPlayerActed PlayerAction.RollDice S.alice)) (S.eventsOf rolledOnce)) "CR 901.9d the roll is a die roll"
    Spec.assertBool s (notElem Action.Type.RollPlanarDie (Action.legalActions S.alice rolledOnce)) "CR 901.9 with no mana the second roll is not offered"
    Spec.assertBool s (elem Action.Type.RollPlanarDie (Action.legalActions S.alice withForest)) "and with a Forest to pay {1} it is"

  -- CR 901.9b / 311.7: the chaos symbol sets off Academy at Tolaria West's
  -- "Whenever chaos ensues, discard your hand." A blank face does nothing.
  Spec.it s "CR 311.7 rolling the chaos symbol triggers the plane's chaos ability" $ do
    forest <- S.printingOf s registry "Forest"
    board <- planarBoard s registry ["Academy at Tolaria West"]
    let (_, one) = S.addHandCard forest S.alice (inMain S.alice board)
        (_, stocked) = S.addHandCard forest S.alice one
        chaos = rollAndResolve 5 stocked
        blank = rollAndResolve 1 stocked
    Spec.assertEqWith s "CR 311.7 chaos: alice discards her hand" (S.handSize S.alice chaos) 0
    Spec.assertEqWith s "CR 901.9a a blank face: she keeps it" (S.handSize S.alice blank) 2

  -- CR 311.7 / 901.6 again, on Tazeem's "draw a card for each land you
  -- control": bob rolls on his own turn, so "you" is bob.
  Spec.it s "CR 901.6 the chaos ability's you is the planar controller" $ do
    forest <- S.printingOf s registry "Forest"
    board <- planarBoard s registry ["Tazeem"]
    let (_, b1) = S.addPermanent forest S.bob board
        (_, b2) = S.addPermanent forest S.bob b1
        (_, b3) = S.addPermanent forest S.alice b2
        chaos = S.runPure (rolling 5) (inMain S.bob b3) (Planechase.roll S.manaPerformer S.bob >> Engine.priorityLoop)
    Spec.assertEqWith s "bob draws one card for each of his two Forests, alice none" (S.handSize S.bob chaos, S.handSize S.alice chaos) (2, 0)

  -- CR 901.8 / 701.31b: the Planeswalker symbol triggers the planeswalking
  -- ability, which puts Academy on the bottom as a new object (CR 311.6) and
  -- turns Tazeem face up.
  Spec.it s "CR 901.8 rolling the Planeswalker symbol planeswalks to the next plane" $ do
    board <- planarBoard s registry ["Academy at Tolaria West", "Tazeem"]
    let main = inMain S.alice board
        walked = rollAndResolve 6 main
        blank = rollAndResolve 1 main
        names gs = fmap (\oid -> fmap Face.name (Game.faceOf oid gs)) (Planechase.faceUp gs)
        academyBefore = Planechase.faceUp main
    Spec.assertEqWith s "CR 701.31b Tazeem is the face-up plane" (names walked) [Just (CardName.MkCardName (Text.pack "Tazeem"))]
    Spec.assertEqWith s "and Academy is on the bottom of the planar deck" (fmap (\oid -> fmap Face.name (Game.faceOf oid walked)) (Planechase.deckOf S.alice walked)) [Just (CardName.MkCardName (Text.pack "Academy at Tolaria West"))]
    Spec.assertBool s (all (\oid -> Maybe.isNothing (Game.lookupObject oid walked)) academyBefore) "CR 311.6 as a new object"
    Spec.assertEqWith s "a blank face leaves Academy face up" (names blank) [Just (CardName.MkCardName (Text.pack "Academy at Tolaria West"))]

  -- CR 901.8: "controlled by the player whose planar die roll caused it to
  -- trigger", and with no source. Three seats, bob active and rolling, so a
  -- gather that gave every player the trigger, or gave it to the first seat,
  -- answers differently.
  Spec.it s "CR 901.8 the planeswalking ability is the roller's alone, with no source" $ do
    board <- seatedPlanarBoard s registry S.bob [(S.alice, ["Academy at Tolaria West"]), (S.bob, ["Tazeem", "Academy at Tolaria West"]), (S.carol, ["Tazeem"])]
    let placed = S.runPure (rolling 6) (inMain S.bob board) (Planechase.roll S.manaPerformer S.bob >> Engine.placePendingTriggers)
        walker oid = case fmap Object.source (Game.lookupObject oid placed) of
          Just (Source.OfInherentTrigger inherent) -> Just (InherentTriggerSource.controller inherent)
          _ -> Nothing
    Spec.assertEqWith s "one sourceless planeswalking ability, bob's" (fmap walker (GameState.stack placed)) [Just S.bob]

  -- CR 901.10 / 311.5 / 800.4p: bob, the active player, concedes in his main
  -- phase while his Academy is the face-up plane. It leaves the game with him,
  -- carol -- the next seat in turn order, not alice, the first by id -- becomes
  -- planar controller, and her top planar card is turned up at once.
  Spec.it s "CR 311.5 a departing active player's plane is replaced from the next seat's planar deck" $ do
    board <- seatedPlanarBoard s registry S.bob [(S.alice, ["Tazeem", "Academy at Tolaria West"]), (S.bob, ["Academy at Tolaria West"]), (S.carol, ["Tazeem", "Academy at Tolaria West"])]
    let gone = S.runPure (conceding S.bob) (inMain S.bob board) Engine.priorityLoop
        tazeem = CardName.MkCardName (Text.pack "Tazeem")
    Spec.assertEqWith s "CR 901.10 carol's Tazeem is face up in place of bob's Academy" (fmap (\oid -> (fmap Face.name (Game.faceOf oid gone), fmap Object.owner (Game.lookupObject oid gone))) (Planechase.faceUp gone)) [(Just tazeem, Just S.carol)]
    Spec.assertEqWith s "CR 311.5 carol controls it" (fmap (`Projection.controllerOf` gone) (Planechase.faceUp gone)) [Just S.carol]
    Spec.assertEqWith s "and alice's planar deck is untouched" (length (Planechase.deckOf S.alice gone), length (Planechase.deckOf S.carol gone)) (2, 1)

  -- CR 901.10a: bob rolls the Planeswalker symbol, and while his planeswalking
  -- ability is on the stack alice, whose Academy is face up, concedes. bob turns
  -- up his Tazeem (CR 901.10) and the ability ceases to exist, so it does not
  -- planeswalk him on to his Academy.
  Spec.it s "CR 901.10a a plane leaving the game ends a pending planeswalking ability" $ do
    board <- seatedPlanarBoard s registry S.alice [(S.alice, ["Academy at Tolaria West"]), (S.bob, ["Tazeem", "Academy at Tolaria West"]), (S.carol, [])]
    let answer :: Prompt.Prompt r -> r
        answer p = case p of
          Prompt.RollDie _ -> 6
          _ -> conceding S.alice p
        gone = S.runPure answer (inMain S.bob board) (Planechase.roll S.manaPerformer S.bob >> Engine.priorityLoop)
        names = fmap (\oid -> fmap Face.name (Game.faceOf oid gone)) (Planechase.faceUp gone)
    Spec.assertEqWith s "CR 901.10a bob's Tazeem is still the face-up plane" names [Just (CardName.MkCardName (Text.pack "Tazeem"))]
    Spec.assertEqWith s "and his Academy is still in his planar deck" (length (Planechase.deckOf S.bob gone)) 1
    Spec.assertBool s (notElem S.alice (Game.stillPlaying gone)) "alice has left the game"

  -- CR 312.5 / 704.6f: alice rolls the Planeswalker symbol and planeswalks
  -- from Academy at Tolaria West to Mutual Epiphany ("When you encounter Mutual
  -- Epiphany, each player draws four cards."). Its ability resolves, and the
  -- state-based action then planeswalks her on to Tazeem.
  Spec.it s "CR 312.5 encountering Mutual Epiphany draws each player four, then CR 704.6f planeswalks away" $ do
    board <- planarBoard s registry ["Academy at Tolaria West", "Mutual Epiphany", "Tazeem"]
    let walked = rollAndResolve 6 (inMain S.alice board)
    Spec.assertEqWith s "CR 312.5 alice and bob each drew four" (S.handSize S.alice walked, S.handSize S.bob walked) (4, 4)
    Spec.assertEqWith s "CR 704.6f Tazeem is the face-up plane" (faceUpNames walked) [cardName "Tazeem"]
    Spec.assertEqWith s "and Academy then Mutual Epiphany are on the bottom of the planar deck" (deckNames S.alice walked) [cardName "Academy at Tolaria West", cardName "Mutual Epiphany"]

  -- CR 312.7 / 704.6f: "isn't the source of a triggered ability that has
  -- triggered but not yet left the stack". Once the planeswalking ability has
  -- resolved, the settle that follows checks state-based actions before it
  -- puts the encounter ability on the stack; Mutual Epiphany stays face up
  -- through both.
  Spec.it s "CR 704.6f a phenomenon stays face up while its encounter ability has triggered" $ do
    board <- planarBoard s registry ["Academy at Tolaria West", "Mutual Epiphany", "Tazeem"]
    let pending = S.runPure (rolling 6) (inMain S.alice board) (Planechase.roll S.manaPerformer S.alice >> Engine.settleForPriority >> Stack.resolveTop >> Engine.settleForPriority)
    Spec.assertEqWith s "CR 704.6f Mutual Epiphany is still face up" (faceUpNames pending) [cardName "Mutual Epiphany"]
    Spec.assertEqWith s "with its ability on the stack and nobody's hand drawn" (length (GameState.stack pending), S.handSize S.alice pending, S.handSize S.bob pending) (1, 0, 0)

  -- CR 901.5: the starting player puts a phenomenon on the bottom while
  -- finding the starting plane, and no ability of it triggers. A regression
  -- fence: CR 312.6 makes the bottomed card a new object, which no ability
  -- triggered on the old one could reach anyway.
  Spec.it s "CR 901.5 a phenomenon passed over for the starting plane does not trigger" $ do
    board <- planarBoard s registry ["Mutual Epiphany", "Academy at Tolaria West"]
    let settled = S.runPure S.identityAnswer (inMain S.alice board) Engine.settleForPriority
    Spec.assertEqWith s "CR 901.5 nobody drew" (S.handSize S.alice settled, S.handSize S.bob settled) (0, 0)
    Spec.assertEqWith s "and Academy is the starting plane" (faceUpNames settled) [cardName "Academy at Tolaria West"]

  -- CR 901.10 / 312.5: bob, the active player, concedes while his Academy is
  -- face up. carol, the new planar controller, turns up her Mutual Epiphany,
  -- which is encountering it: alice and carol draw four, and carol then
  -- planeswalks on to her Tazeem.
  Spec.it s "CR 901.10 a phenomenon turned up when a plane's owner leaves is encountered" $ do
    board <- seatedPlanarBoard s registry S.bob [(S.alice, ["Tazeem"]), (S.bob, ["Academy at Tolaria West"]), (S.carol, ["Mutual Epiphany", "Tazeem"])]
    let gone = S.runPure (conceding S.bob) (inMain S.bob board) Engine.priorityLoop
    Spec.assertEqWith s "CR 312.5 alice and carol each drew four" (S.handSize S.alice gone, S.handSize S.carol gone) (4, 4)
    Spec.assertEqWith s "CR 704.6f carol's Tazeem is face up" (fmap (\oid -> (fmap Face.name (Game.faceOf oid gone), fmap Object.owner (Game.lookupObject oid gone))) (Planechase.faceUp gone)) [(cardName "Tazeem", Just S.carol)]

  -- CR 901.10b: alice's Mutual Epiphany ability is on the stack when she
  -- concedes. The card leaves with her and bob, the next planar controller,
  -- turns up his Tazeem (CR 901.10), but the ability stays, now bob's, and bob
  -- and carol each draw four.
  Spec.it s "CR 901.10b a phenomenon's ability stays on the stack when its owner leaves" $ do
    board <- seatedPlanarBoard s registry S.alice [(S.alice, ["Academy at Tolaria West", "Mutual Epiphany"]), (S.bob, ["Tazeem"]), (S.carol, [])]
    let pending = S.runPure (rolling 6) (inMain S.alice board) (Planechase.roll S.manaPerformer S.alice >> Engine.settleForPriority >> Stack.resolveTop >> Engine.settleForPriority)
        controllers = fmap (`Projection.controllerOf` pending) (GameState.stack pending)
        gone = S.runPure (conceding S.alice) pending Engine.priorityLoop
    Spec.assertEqWith s "CR 901.10b bob and carol each drew four" (S.handSize S.bob gone, S.handSize S.carol gone) (4, 4)
    Spec.assertBool s (notElem S.alice (Game.stillPlaying gone)) "alice has left the game"
    Spec.assertEqWith s "CR 901.10 bob's Tazeem is face up" (fmap (\oid -> (fmap Face.name (Game.faceOf oid gone), fmap Object.owner (Game.lookupObject oid gone))) (Planechase.faceUp gone)) [(cardName "Tazeem", Just S.bob)]
    Spec.assertEqWith s "the ability was alice's while she played" controllers [Just S.alice]

  -- CR 311.7: Path of the Enigma ("Target player draws four cards. Will of the
  -- Planeswalkers -- ... If planeswalk gets more votes, planeswalk. If chaos
  -- gets more votes or the vote is tied, chaos ensues.") cast by alice under
  -- Academy at Tolaria West ("Whenever chaos ensues, discard your hand."),
  -- targeting bob, with two Forests in her hand. A tied vote makes chaos
  -- ensue; two votes for planeswalk planeswalk her to Tazeem instead.
  Spec.it s "CR 311.7 Path of the Enigma's tied vote makes chaos ensue, and a planeswalk vote planeswalks" $ do
    board <- planarBoard s registry ["Academy at Tolaria West", "Tazeem"]
    (enigmaCard, enigma) <- enigmaBoard s registry board
    let tied = S.runPure (enigmaAnswer "planeswalk" "chaos") enigma (S.cast S.alice enigmaCard >> Engine.priorityLoop)
        walked = S.runPure (enigmaAnswer "planeswalk" "planeswalk") enigma (S.cast S.alice enigmaCard >> Engine.priorityLoop)
    Spec.assertEqWith s "CR 311.7 on the tie Academy's chaos ability discarded alice's two Forests" (S.handSize S.alice tied) 0
    Spec.assertEqWith s "and Academy is still the face-up plane" (faceUpNames tied) [cardName "Academy at Tolaria West"]
    Spec.assertEqWith s "bob drew four" (S.handSize S.bob tied) 4
    Spec.assertEqWith s "CR 701.31 on planeswalk votes alice planeswalked to Tazeem" (faceUpNames walked) [cardName "Tazeem"]
    Spec.assertEqWith s "and kept her two Forests" (S.handSize S.alice walked) 2

  -- CR 614.1a on CR 701.31b: alice controls Susan Foreman ("If you would
  -- planeswalk, instead look at the top two cards of your planar deck, put one
  -- on the bottom of your planar deck and the other on top, then planeswalk.")
  -- and rolls the Planeswalker symbol under Academy at Tolaria West with Tazeem
  -- then Naya below it. She puts Naya on top, the second card she is offered,
  -- so she planeswalks to Naya and Tazeem goes to the bottom. Without Susan the
  -- same answers planeswalk her to Tazeem.
  Spec.it s "CR 614.1a Susan Foreman rearranges the top two planar cards before a planeswalk" $ do
    susan <- S.printingOf s registry "Susan Foreman"
    board <- planarBoard s registry ["Academy at Tolaria West", "Tazeem", "Naya"]
    let (_, withSusan) = S.addPermanent susan S.alice (inMain S.alice board)
        walked = S.runPure (rollingKeepingLast 6) withSusan (Planechase.roll S.manaPerformer S.alice >> Engine.priorityLoop)
        without = S.runPure (rollingKeepingLast 6) (inMain S.alice board) (Planechase.roll S.manaPerformer S.alice >> Engine.priorityLoop)
    Spec.assertEqWith s "CR 614.1a alice planeswalked to Naya" (faceUpNames walked) [cardName "Naya"]
    Spec.assertEqWith s "with Tazeem then Academy below" (deckNames S.alice walked) [cardName "Tazeem", cardName "Academy at Tolaria West"]
    Spec.assertEqWith s "without Susan she planeswalks to Tazeem" (faceUpNames without) [cardName "Tazeem"]

  -- CR 701.31c / 901.10: on bob's turn alice, whose Academy at Tolaria West is
  -- the face-up plane, concedes. bob, the planar controller, controls Susan
  -- Foreman, so the turn-up is a planeswalk she replaces: he puts Naya, the
  -- second card offered, above Tazeem and turns it up. Without Susan the same
  -- answers turn up Tazeem.
  Spec.it s "CR 701.31c Susan Foreman arranges the planeswalk a plane's departing owner causes" $ do
    susan <- S.printingOf s registry "Susan Foreman"
    board <- seatedPlanarBoard s registry S.alice [(S.alice, ["Academy at Tolaria West"]), (S.bob, ["Tazeem", "Naya"]), (S.carol, [])]
    let main = inMain S.bob board
        (_, withSusan) = S.addPermanent susan S.bob main
        walked = S.runPure (concedingKeepingLast S.alice) withSusan Engine.priorityLoop
        without = S.runPure (concedingKeepingLast S.alice) main Engine.priorityLoop
    Spec.assertEqWith s "CR 701.31c bob planeswalked to Naya" (faceUpNames walked) [cardName "Naya"]
    Spec.assertEqWith s "with Tazeem still in his planar deck" (deckNames S.bob walked) [cardName "Tazeem"]
    Spec.assertEqWith s "without Susan he turns up Tazeem" (faceUpNames without) [cardName "Tazeem"]
    Spec.assertBool s (notElem S.alice (Game.stillPlaying walked)) "alice has left the game"

  -- CR 312.5 / 614.1a / 701.31c: alice planeswalks to Fixed Point in Time ("When
  -- you encounter Fixed Point in Time, until your next turn, if a player would
  -- planeswalk as a result of rolling the planar die, chaos ensues instead.").
  -- Its CR 704.6f planeswalk away is not the planar die's, so she reaches
  -- Tazeem ("Whenever chaos ensues, draw a card for each land you control.").
  -- She rolls the Planeswalker symbol again, paying {1} with her one Forest:
  -- chaos ensues instead, so she draws one and Naya stays in the deck.
  Spec.it s "CR 614.1a Fixed Point in Time turns a planar die planeswalk into chaos" $ do
    forest <- S.printingOf s registry "Forest"
    board <- planarBoard s registry ["Academy at Tolaria West", "Fixed Point in Time", "Tazeem", "Naya"]
    let (_, withForest) = S.addPermanent forest S.alice (inMain S.alice board)
        first = S.runPure (rolling 6) withForest (Planechase.roll S.manaPerformer S.alice >> Engine.priorityLoop)
        second = S.runPure (rolling 6) first (Planechase.roll S.manaPerformer S.alice >> Engine.priorityLoop)
    Spec.assertEqWith s "CR 704.6f the walk away from Fixed Point in Time reached Tazeem" (faceUpNames first) [cardName "Tazeem"]
    Spec.assertEqWith s "CR 614.1a the second Planeswalker symbol left Tazeem face up" (faceUpNames second) [cardName "Tazeem"]
    Spec.assertEqWith s "CR 311.7 and chaos ensued: alice drew one for her Forest" (S.handSize S.alice second) 1
  carrySpec s registry

-- CR 400.7b / 611.3d on The Caldaia, Plane -- Capenna, "Creature spells you cast
-- from your hand have blitz {3}." (Oracle text checked on Scryfall,
-- 2026-10-12). The plane grants blitz to the SPELL; CR 400.7b keeps the grant on
-- the permanent, where CR 702.152a's haste and draw function. Hunting
-- Velociraptor's prowl, which functions only on the stack (CR 702.76a), is the
-- grant that stays behind; Sabin, Master Monk is the creature holding a blitz
-- of its own beside the plane's (CR 702.152b).
--
-- Every board has The Caldaia face up, six Mountains and the creature in
-- alice's hand, so a negative cannot be a shortage.
carrySpec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
carrySpec s registry = Spec.describe s "CR 400.7b" $ do
  Spec.it s "CR 400.7b a Hill Giant cast for The Caldaia's blitz has haste, is sacrificed at the end step and draws; hard-cast it does neither" $ do
    (giantId, board) <- caldaiaBoard s registry "Hill Giant" []
    let blitzed = throughEndStep 8 (castPaying [ManaSymbol.Generic 3] giantId board)
        hardCast = throughEndStep 8 (castPaying [ManaSymbol.Generic 3, theRed] giantId board)
    Spec.assertEqWith s "CR 400.7b / 702.152a the blitzed Giant attacked bob for 3" (S.lifeOf S.bob blitzed) (Just 17)
    Spec.assertEqWith s "CR 702.152a it was sacrificed at the end step and drew a card as it died" (named "Hill Giant" blitzed, drawn blitzed) ([], 1)
    Spec.assertEqWith s "hard-cast, it neither attacked nor was sacrificed" (S.lifeOf S.bob hardCast, length (named "Hill Giant" hardCast), drawn hardCast) (Just 20, 1, 0)
  Spec.it s "CR 400.7b a Ridgetop Raptor keeps The Caldaia's blitz and not Hunting Velociraptor's prowl" $ do
    (raptorId, board) <- caldaiaBoard s registry "Ridgetop Raptor" ["Hunting Velociraptor"]
    let onStack = S.runPure (paying [ManaSymbol.Generic 3]) board (S.cast S.alice raptorId)
        resolved = S.runPure (paying []) onStack (Stack.resolveTop >> Engine.settleForPriority)
        spellKeywords = foldMap (\o -> Map.keysSet (Projection.keywordsOf o onStack)) (filter (\o -> Game.zoneOf o onStack == Just Zone.Stack) (Map.keys (GameState.objects onStack)))
        keywordsOf = case named "Ridgetop Raptor" resolved of
          [permanent] -> Map.keysSet (Projection.keywordsOf permanent resolved)
          _ -> Set.empty
        has keywords = (Set.member caldaiaBlitz keywords, Set.member velociraptorProwl keywords)
    Spec.assertEqWith s "CR 601.2a the spell had both grants" (has spellKeywords) (True, True)
    Spec.assertEqWith s "CR 400.7b the permanent keeps the blitz and not the prowl" (has keywordsOf) (True, False)
  -- CR 707.10 / 707.2 on Double Major {G}{U}, "Copy target creature spell you
  -- control, except it isn't legendary if the spell is legendary." The copy was
  -- not cast, so The Caldaia's "from your hand" does not reach it, and its
  -- record of the blitz paid arms no sacrifice once it holds no blitz to say so.
  Spec.it s "CR 707.10 a Double Major copy of a Giant cast for The Caldaia's blitz gets neither haste nor the sacrifice" $ do
    (giantId, board) <- caldaiaBoard s registry "Hill Giant" []
    forest <- S.printingOf s registry "Forest"
    island <- S.printingOf s registry "Island"
    major <- S.printingOf s registry "Double Major"
    let onStack = S.runPure (paying [ManaSymbol.Generic 3]) board (S.cast S.alice giantId)
        (majorId, withMajor) = S.addHandCard major S.alice (S.landsFor island S.alice 1 (S.landsFor forest S.alice 1 onStack))
        resolved = S.runPure (paying []) withMajor (S.cast S.alice majorId >> Monad.replicateM_ (3 :: Int) (Engine.settleForPriority >> Stack.resolveTop) >> Engine.settleForPriority)
        after = throughEndStep 8 resolved
    Spec.assertEqWith s "CR 707.10 only the cast Giant attacked bob, for 3" (S.lifeOf S.bob after) (Just 17)
    Spec.assertEqWith s "CR 702.152a only the cast Giant was sacrificed and drew; the token copy stayed" (length (named "Hill Giant" after), drawn after) (1, 1)
  -- CR 702.85a's cascade "functions only while the spell with cascade is on the
  -- stack": Imoti, Celebrant of Bounty's grant to a Trained Orgg {6}{R} is a
  -- trigger of the stack, which Keyword.functionsOnBattlefield reads off the
  -- roster it is minted into.
  Spec.it s "CR 400.7b a Trained Orgg keeps The Caldaia's blitz and not Imoti's cascade" $ do
    (orggId, board) <- caldaiaBoard s registry "Trained Orgg" ["Imoti, Celebrant of Bounty"]
    let onStack = S.runPure (paying [ManaSymbol.Generic 3]) board (S.cast S.alice orggId)
        resolved = S.runPure (paying []) onStack (Monad.replicateM_ (2 :: Int) (Stack.resolveTop >> Engine.settleForPriority))
        keywordsOf = case named "Trained Orgg" resolved of
          [permanent] -> Map.keysSet (Projection.keywordsOf permanent resolved)
          _ -> Set.empty
    Spec.assertEqWith s "CR 400.7b the permanent keeps the blitz and not the cascade" (Set.member caldaiaBlitz keywordsOf, Set.member Keyword.Cascade keywordsOf) (True, False)
  Spec.it s "CR 702.152b Sabin under The Caldaia draws once for whichever blitz was paid, and not at all hard-cast" $ do
    (sabinId, board) <- caldaiaBoard s registry "Sabin, Master Monk" []
    let -- Double strike adds CR 510.4's first-strike damage step.
        through wanted = throughEndStep 9 (castPaying wanted sabinId board)
        plane = through [ManaSymbol.Generic 3]
        own = through [ManaSymbol.Generic 2, theRed, theRed]
        printed = through [ManaSymbol.Generic 4, theRed]
    Spec.assertEqWith s "CR 702.152b paid the plane's blitz, Sabin drew one card" (drawn plane) 1
    Spec.assertEqWith s "CR 702.152b paid its own blitz, Sabin drew one card" (drawn own) 1
    Spec.assertEqWith s "hard-cast, with both blitz abilities unpaid, it drew nothing and stayed" (drawn printed, length (named "Sabin, Master Monk" printed)) (0, 1)

-- alice on turn with The Caldaia face up, six Mountains, `creature` and a
-- Mountain to discard in hand, and `others` on her battlefield.
caldaiaBoard :: (Monad m) => Spec.Spec m n -> Registry.Registry m -> String -> [String] -> m (ObjectId.ObjectId, GameState.GameState)
caldaiaBoard s registry creature others = do
  mountain <- S.printingOf s registry "Mountain"
  card <- S.printingOf s registry creature
  permanents <- traverse (S.printingOf s registry) others
  board <- planarBoard s registry ["The Caldaia"]
  let (creatureId, gs1) = S.addHandCard card S.alice (S.landsFor mountain S.alice 6 board)
      (_, gs2) = S.addHandCard mountain S.alice gs1
      gs3 = List.foldl' (\g p -> snd (S.addPermanent p S.alice g)) gs2 permanents
  pure (creatureId, (inMain S.alice gs3) {GameState.remaining = S.phasesAfter Phase.PrecombatMain})

-- CR 601.2b answered with `wanted`'s mana, and every attack with everything.
paying :: [ManaSymbol.ManaSymbol] -> Prompt.Prompt r -> r
paying wanted p = case p of
  Prompt.ChooseCost _ _ _ candidates -> Maybe.fromMaybe (Cost.firstOffered candidates) (List.find ((== Just (ManaCost.MkManaCost wanted)) . Cost.Type.mana . CandidateCost.cost) candidates)
  Prompt.DeclareAttackers {} -> S.aggressiveAnswer p
  _ -> S.identityAnswer p

-- Cast `oid` for alice paying `wanted`, and resolve it.
castPaying :: [ManaSymbol.ManaSymbol] -> ObjectId.ObjectId -> GameState.GameState -> GameState.GameState
castPaying wanted oid gs = S.runPure (paying wanted) (S.runPure (paying wanted) gs (S.cast S.alice oid)) (Stack.resolveTop >> Engine.settleForPriority)

-- `n` steps on from the precombat main phase, attacking with everything: eight
-- reach the end step and resolve its delayed triggers.
throughEndStep :: Int -> GameState.GameState -> GameState.GameState
throughEndStep n gs = List.foldl' (\g _ -> S.runPure (paying []) g Engine.runStep) gs [1 .. n]

named :: String -> GameState.GameState -> [ObjectId.ObjectId]
named name gs = filter (\o -> Projection.hasName (CardName.MkCardName (Text.pack name)) o gs) (Set.toList (GameState.battlefield gs))

-- The cards alice drew: her library starts at twenty.
drawn :: GameState.GameState -> Int
drawn gs = 20 - length (Game.zoneMembers Zone.Library S.alice gs)

theRed :: ManaSymbol.ManaSymbol
theRed = ManaSymbol.OfType (ManaType.Colored Color.Red)

caldaiaBlitz :: Keyword.Keyword
caldaiaBlitz = Keyword.Blitz (Cost.Type.MkCost (Just (ManaCost.MkManaCost [ManaSymbol.Generic 3])) [])

velociraptorProwl :: Keyword.Keyword
velociraptorProwl = Keyword.Prowl (Cost.Type.MkCost (Just (ManaCost.MkManaCost [ManaSymbol.Generic 2, theRed])) [])

-- alice's five Islands, and Path of the Enigma and two Forests in her hand, in
-- her main phase.
enigmaBoard :: (Monad m) => Spec.Spec m n -> Registry.Registry m -> GameState.GameState -> m (ObjectId.ObjectId, GameState.GameState)
enigmaBoard s registry gs = do
  island <- S.printingOf s registry "Island"
  forest <- S.printingOf s registry "Forest"
  path <- S.printingOf s registry "Path of the Enigma"
  let lands = List.foldl' (\g _ -> snd (S.addPermanent island S.alice g)) (inMain S.alice gs) [1 .. 5 :: Int]
      held = List.foldl' (\g _ -> snd (S.addHandCard forest S.alice g)) lands [1 .. 2 :: Int]
  pure (S.addHandCard path S.alice held)

-- Path of the Enigma's answers: bob is the target, alice votes `alices` and bob
-- `bobs`.
enigmaAnswer :: String -> String -> Prompt.Prompt r -> r
enigmaAnswer alices bobs p = case p of
  Prompt.ChooseTargets _ _ _ sets -> fmap (const (Set.singleton (Recipient.ToPlayer S.bob))) sets
  Prompt.ChooseVoteWord _ pid _ offered ->
    let wanted = SlotName.MkSlotName (Text.pack (if pid == S.alice then alices else bobs))
     in Maybe.fromMaybe (NonEmpty.head offered) (List.find (== wanted) (NonEmpty.toList offered))
  _ -> S.identityAnswer p

-- The planar die shows `n`, and a choice among cards takes the last one
-- offered, which is not the default.
rollingKeepingLast :: Natural -> Prompt.Prompt r -> r
rollingKeepingLast n p = case p of
  Prompt.ChooseCardFromAmong _ _ _ candidates -> NonEmpty.last candidates
  _ -> rolling n p

-- `who` concedes, and a choice among cards takes the last one offered.
concedingKeepingLast :: PlayerId.PlayerId -> Prompt.Prompt r -> r
concedingKeepingLast who p = case p of
  Prompt.ChooseCardFromAmong _ _ _ candidates -> NonEmpty.last candidates
  _ -> conceding who p

-- The names of the face-up planar cards.
faceUpNames :: GameState.GameState -> [Maybe CardName.CardName]
faceUpNames gs = fmap (\oid -> fmap Face.name (Game.faceOf oid gs)) (Planechase.faceUp gs)

-- The names in this player's planar deck, top first.
deckNames :: PlayerId.PlayerId -> GameState.GameState -> [Maybe CardName.CardName]
deckNames pid gs = fmap (\oid -> fmap Face.name (Game.faceOf oid gs)) (Planechase.deckOf pid gs)

cardName :: String -> Maybe CardName.CardName
cardName = Just . CardName.MkCardName . Text.pack

-- A two-player board with alice's planar deck stacked in the order named, top
-- first, the top one face up (CR 103.7), and twenty Forests in each library.
-- No opening hands are drawn, so both hands are empty.
planarBoard :: (Monad m) => Spec.Spec m n -> Registry.Registry m -> [String] -> m GameState.GameState
planarBoard s registry order = do
  forest <- S.printingOf s registry "Forest"
  planes <- traverse (S.printingOf s registry) order
  let alices = (Deck.fromCards (Map.singleton forest 20)) {Deck.sideDecks = Map.singleton SideDeck.Planar (Map.fromSet (const 1) (Set.fromList planes))}
      bobs = Deck.fromCards (Map.singleton forest 20)
      built = S.runPure S.identityAnswer (Setup.emptyGame S.bothPlayers) (Setup.createDeck S.alice alices >> Setup.createDeck S.bob bobs)
      rank oid = maybe (length order) (\face -> Maybe.fromMaybe (length order) (List.elemIndex (Face.name face) (fmap (CardName.MkCardName . Text.pack) order))) (Game.faceOf oid built)
      stacked = Game.overSideDecks SideDeck.Planar (Map.adjust (Seq.sortOn rank) S.alice) built
  pure (S.runPure S.identityAnswer stacked (Planechase.setStartingPlane S.alice))

-- A board seated in the order named, each seat's planar deck stacked in the
-- order named, top first, and `starter`'s top card face up (CR 103.7). Twenty
-- Forests in each library; no opening hands.
seatedPlanarBoard :: (Monad m) => Spec.Spec m n -> Registry.Registry m -> PlayerId.PlayerId -> [(PlayerId.PlayerId, [String])] -> m GameState.GameState
seatedPlanarBoard s registry starter seats = do
  forest <- S.printingOf s registry "Forest"
  decks <- traverse (\(pid, order) -> (\planes -> (pid, (Deck.fromCards (Map.singleton forest 20)) {Deck.sideDecks = Map.singleton SideDeck.Planar (Map.fromSet (const 1) (Set.fromList planes))})) <$> traverse (S.printingOf s registry) order) seats
  let seated = Maybe.fromMaybe S.threePlayers (NonEmpty.nonEmpty (fmap fst seats))
      built = S.runPure S.identityAnswer (Setup.emptyGame seated) (mapM_ (uncurry Setup.createDeck) decks)
      rank order oid = maybe (length order) (\face -> Maybe.fromMaybe (length order) (List.elemIndex (Face.name face) (fmap (CardName.MkCardName . Text.pack) order))) (Game.faceOf oid built)
      stacked = Game.overSideDecks SideDeck.Planar (Map.mapWithKey (\pid deck -> maybe deck (\order -> Seq.sortOn (rank order) deck) (List.lookup pid seats))) built
  pure (S.runPure S.identityAnswer stacked (Planechase.setStartingPlane starter))

-- `who` concedes when asked; everyone else plays on, and every other prompt is
-- answered by identity.
conceding :: PlayerId.PlayerId -> Prompt.Prompt r -> r
conceding who p = case p of
  Prompt.Concede asked -> if asked == who then Concession.Concedes else Concession.Continues
  _ -> S.identityAnswer p

-- `pid`'s precombat main phase with priority and an empty stack.
inMain :: PlayerId.PlayerId -> GameState.GameState -> GameState.GameState
inMain pid gs = gs {GameState.activePlayer = pid, GameState.phase = Phase.PrecombatMain, GameState.priority = Just pid}

-- `pid`'s end step begins and every trigger resolves.
endStep :: PlayerId.PlayerId -> GameState.GameState -> GameState.GameState
endStep pid gs =
  let step = Phase.Ending EndingStep.EndStep
      begun = Event.recordEvent (GameEvent.StepBegan (StepBegan.MkStepBegan step pid)) (gs {GameState.activePlayer = pid, GameState.phase = step, GameState.priority = Just pid})
   in S.runPure S.identityAnswer begun Engine.priorityLoop

-- Answer the planar die with this number and everything else by identity.
rolling :: Natural -> Prompt.Prompt r -> r
rolling n p = case p of
  Prompt.RollDie _ -> n
  _ -> S.identityAnswer p

-- alice rolls the planar die showing `n`, and whatever it triggers resolves.
rollAndResolve :: Natural -> GameState.GameState -> GameState.GameState
rollAndResolve n gs = S.runPure (rolling n) gs (Planechase.roll S.manaPerformer S.alice >> Engine.priorityLoop)
