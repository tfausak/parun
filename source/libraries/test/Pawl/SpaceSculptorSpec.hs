{-# LANGUAGE GADTs #-}

-- Covers CR 702.158's space sculptor (Pawl.Engine.SpaceSculptor and
-- Pawl.Engine.Sector): CR 704.5u's sector assignment and its choice order, CR
-- 702.158b's ending, CR 702.158d's "choose a sector" (Effect.ChooseSector) and
-- CR 702.158e's "same sector" (Filter.SameSectorAsSource), all through Space
-- Beleren.
--
-- A test-local answerer rather than the scenario harness, because the subject
-- is the ORDER the sector prompts are put in, which the answerer logs.
module Pawl.SpaceSculptorSpec where

import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Set as Set
import qualified Numeric.Natural as Natural
import qualified Pawl.Engine.Activate as Activate
import qualified Pawl.Engine.Combat as Combat
import qualified Pawl.Engine.Engine as Engine
import qualified Pawl.Engine.Event as Event
import qualified Pawl.Engine.Game as Game
import qualified Pawl.Engine.Sector as Sector
import qualified Pawl.Engine.Stack as Stack
import qualified Pawl.Registry as Registry
import qualified Pawl.Spec as Spec
import qualified Pawl.Support as S
import qualified Pawl.Types.ActivatedAbility as ActivatedAbility
import qualified Pawl.Types.Card as Card
import qualified Pawl.Types.CounterKind as CounterKind
import qualified Pawl.Types.Designation as Designation
import qualified Pawl.Types.Face as Face
import Pawl.Types.Game (Game)
import qualified Pawl.Types.GameState as GameState
import qualified Pawl.Types.GrantedAbility as GrantedAbility
import qualified Pawl.Types.Object as Object
import qualified Pawl.Types.ObjectId as ObjectId
import qualified Pawl.Types.Phase as Phase
import qualified Pawl.Types.PlayerId as PlayerId
import qualified Pawl.Types.Printing as Printing
import qualified Pawl.Types.Prompt as Prompt
import qualified Pawl.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
spec s registry = Spec.describe s "SpaceSculptor" $ do
  -- Three seats, so "opponents assign first" is told apart from APNAP order:
  -- alice is active AND controls the sculptor, so plain APNAP would ask her
  -- first. A board without the Beleren is the pair, asking nobody.
  Spec.it s "CR 704.5u the creatures' controllers choose their sectors, sculptor's controller last" $ do
    beleren <- S.printingOf s registry "Space Beleren"
    bears <- S.printingOf s registry "Grizzly Bears"
    let (mine, g1) = S.addPermanent bears S.alice S.threePlayerGame
        (bobs, g2) = S.addPermanent bears S.bob g1
        (carols, g3) = S.addPermanent bears S.carol g2
        (belerenId, g4) = S.addPermanent beleren S.alice g3
        withBeleren = withLoyalty 3 belerenId g4
        picks = Map.fromList [(mine, Designation.GammaSector), (bobs, Designation.BetaSector), (carols, Designation.AlphaSector)]
        (asked, after) = run picks withBeleren Engine.settleForPriority
        (askedCarolFirst, _) = run picks withBeleren {GameState.activePlayer = S.carol} Engine.settleForPriority
        (askedWithout, without) = run picks g3 Engine.settleForPriority
    Spec.assertEqWith s "each creature is in the sector its controller chose" (fmap (`sectorsOf` after) [mine, bobs, carols]) [[Designation.GammaSector], [Designation.BetaSector], [Designation.AlphaSector]]
    Spec.assertEqWith s "bob and carol choose before alice, who controls the Beleren" asked [(S.bob, bobs), (S.carol, carols), (S.alice, mine)]
    Spec.assertEqWith s "the opponents themselves in APNAP order (CR 101.4)" askedCarolFirst [(S.carol, carols), (S.bob, bobs), (S.alice, mine)]
    Spec.assertEqWith s "without a sculptor nobody is asked" askedWithout []
    Spec.assertEqWith s "and nothing is in a sector" (fmap (`sectorsOf` without) [mine, bobs, carols]) [[], [], []]

  -- The -1 over two sectors: bob's two creatures are in beta, alice's in alpha.
  -- Beta is not the prompt's default answer (alpha is), so an ignored answer
  -- would put the counter on the wrong creature.
  Spec.it s "CR 702.158d Space Beleren's -1 puts a counter on each creature in the chosen sector only" $ do
    (board0, beleren, bears) <- belerenBoard s registry 3
    let (mine, g1) = S.addPermanent bears S.alice board0
        (bobs1, g2) = S.addPermanent bears S.bob g1
        (bobs2, board) = S.addPermanent bears S.bob g2
    withAbilities s registry $ \(_, minus1, _) -> do
      let picks = Map.fromList [(mine, Designation.AlphaSector), (bobs1, Designation.BetaSector), (bobs2, Designation.BetaSector), (beleren, Designation.BetaSector)]
          (asked, after) = run picks board (Engine.settleForPriority >> Activate.activateAbility S.alice beleren minus1 >> Stack.resolveTop >> Engine.settleForPriority)
      Spec.assertEqWith s "the two beta creatures get a counter and the alpha one none" (fmap (`plusCounters` after) [bobs1, bobs2, mine]) [1, 1, 0]
      Spec.assertBool s ((S.alice, beleren) `elem` asked) "alice is asked which sector"

  -- The -5, with the Beleren GONE before it resolves: CR 702.158b keeps the
  -- sectors while "an ability whose source has space sculptor" is on the stack,
  -- so the -5 still finds them.
  Spec.it s "CR 702.158b / 702.158d Space Beleren's -5 destroys the chosen sector after the Beleren has left" $ do
    (board0, beleren, bears) <- belerenBoard s registry 6
    let (mine, g1) = S.addPermanent bears S.alice board0
        (bobs1, g2) = S.addPermanent bears S.bob g1
        (bobs2, board) = S.addPermanent bears S.bob g2
    withAbilities s registry $ \(_, _, minus5) -> do
      let picks = Map.fromList [(mine, Designation.GammaSector), (bobs1, Designation.GammaSector), (bobs2, Designation.BetaSector), (beleren, Designation.GammaSector)]
          (_, after) = run picks board $ do
            Engine.settleForPriority
            Activate.activateAbility S.alice beleren minus5
            Event.changeZone beleren Zone.Graveyard
            Engine.settleForPriority
            Stack.resolveTop
            Engine.settleForPriority
      Spec.assertEqWith s "the two gamma creatures are destroyed and the beta one is not" (fmap (`onBattlefield` after) [mine, bobs1, bobs2]) [False, False, True]
      Spec.assertEqWith s "and the survivor's sector ends with the ability" (sectorsOf bobs2 after) []

  -- CR 702.158b's ending, and the moment it is read: a Beleren destroyed ends
  -- every sector; a Beleren flickered by one action ends them too, so CR 704.5u
  -- asks again, where a Beleren left alone asks once.
  Spec.it s "CR 702.158b the sectors end when no player controls a sculptor, even for a moment" $ do
    (board0, beleren, bears) <- belerenBoard s registry 3
    let (mine, g1) = S.addPermanent bears S.alice board0
        (bobs, board) = S.addPermanent bears S.bob g1
    let picks = Map.fromList [(mine, Designation.BetaSector), (bobs, Designation.GammaSector)]
        (_, destroyed) = run picks board (Engine.settleForPriority >> Event.changeZone beleren Zone.Graveyard >> Engine.settleForPriority)
        flicker = do
          returned <- Event.changeZoneReturning beleren Zone.Exile
          mapM_ (`Event.changeZone` Zone.Battlefield) returned
        (askedFlickered, _) = run picks board (Engine.settleForPriority >> flicker >> Engine.settleForPriority)
        (askedStill, _) = run picks board (Engine.settleForPriority >> Engine.settleForPriority)
    Spec.assertEqWith s "the Beleren gone, nothing is in a sector" (fmap (`sectorsOf` destroyed) [mine, bobs]) [[], []]
    Spec.assertEqWith s "the Beleren flickered, each creature is asked again" askedFlickered [(S.bob, bobs), (S.alice, mine), (S.bob, bobs), (S.alice, mine)]
    Spec.assertEqWith s "the Beleren left alone, each is asked once" askedStill [(S.bob, bobs), (S.alice, mine)]

  -- The +1, read through Combat.pairAllowed, CR 509.1c's "able to block". Bob's
  -- alpha creature may block alice's alpha attacker and his beta one may not;
  -- before the +1 resolves, both may. A creature in no sector is unrestricted
  -- as an attacker and barred as a blocker.
  Spec.it s "CR 702.158e Space Beleren's +1 lets a creature be blocked only from its own sector" $ do
    (board0, beleren, bears) <- belerenBoard s registry 3
    let (mine, g1) = S.addPermanent bears S.alice board0
        (bobsAlpha, g2) = S.addPermanent bears S.bob g1
        (bobsBeta, board) = S.addPermanent bears S.bob g2
    withAbilities s registry $ \(plus1, _, _) -> do
      let picks = Map.fromList [(mine, Designation.AlphaSector), (bobsAlpha, Designation.AlphaSector), (bobsBeta, Designation.BetaSector)]
          (_, sectored) = run picks board Engine.settleForPriority
          (_, restricted) = run picks sectored (Activate.activateAbility S.alice beleren plus1 >> Stack.resolveTop >> Engine.settleForPriority)
          able gs blocker = Combat.pairAllowed [bobsAlpha, bobsBeta] [mine] blocker mine gs
          -- A creature in no sector, placed after the +1 with no settle between,
          -- so CR 704.5u has not yet given it one: alice's as an attacker, bob's
          -- as a blocker. The rule's "creatures in each sector" leaves the first
          -- unrestricted; the second shares no sector with alice's alpha one.
          (loose, withLoose) = S.addPermanent bears S.alice restricted
          (bobsLoose, withBoth) = S.addPermanent bears S.bob withLoose
          ableAgainst attacker blocker = Combat.pairAllowed [bobsAlpha, bobsBeta, bobsLoose] [mine, loose] blocker attacker withBoth
      Spec.assertEqWith s "after the +1, only the alpha creature may block the alpha attacker" (fmap (able restricted) [bobsAlpha, bobsBeta]) [True, False]
      Spec.assertEqWith s "an attacker in no sector may still be blocked by any creature" (fmap (ableAgainst loose) [bobsAlpha, bobsBeta, bobsLoose]) [True, True, True]
      Spec.assertEqWith s "a creature in no sector may not block the alpha attacker" (ableAgainst mine bobsLoose) False
      Spec.assertEqWith s "before it, both may" (fmap (able sectored) [bobsAlpha, bobsBeta]) [True, True]

-- Answers every sector prompt from `picks` by the object it names -- the
-- creature CR 704.5u assigns, or the Beleren as its ability resolves -- logging
-- who was asked about what, in order. Everything else is S.identityAnswer.
sectoring :: Map.Map ObjectId.ObjectId Designation.Designation -> Prompt.Prompt r -> State.State [(PlayerId.PlayerId, ObjectId.ObjectId)] r
sectoring picks p = case p of
  Prompt.ChooseSector _ who oid offered -> do
    State.modify' (<> [(who, oid)])
    pure (Maybe.fromMaybe (NonEmpty.head offered) (Map.lookup oid picks))
  _ -> pure (S.identityAnswer p)

run :: Map.Map ObjectId.ObjectId Designation.Designation -> GameState.GameState -> Game a -> ([(PlayerId.PlayerId, ObjectId.ObjectId)], GameState.GameState)
run picks gs game =
  let ((_, after), asked) = State.runState (Engine.runGame (sectoring picks) gs game) []
   in (asked, after)

-- A two-seat board in alice's main phase with her priority, holding only Space
-- Beleren with `loyalty` loyalty counters; the Grizzly Bears printing comes
-- back for the caller to place.
belerenBoard :: (Monad m) => Spec.Spec m n -> Registry.Registry m -> Natural.Natural -> m (GameState.GameState, ObjectId.ObjectId, Printing.Printing)
belerenBoard s registry loyalty = do
  beleren <- S.printingOf s registry "Space Beleren"
  bears <- S.printingOf s registry "Grizzly Bears"
  let (belerenId, placed) = S.addPermanent beleren S.alice (S.landsInPlay bears 0)
  pure ((withLoyalty loyalty belerenId placed) {GameState.phase = Phase.PrecombatMain, GameState.activePlayer = S.alice, GameState.priority = Just S.alice}, belerenId, bears)

-- CR 306.5b's loyalty counters, which S.addPermanent's direct placement does
-- not give: without them CR 704.5i buries the Beleren on the first pass.
withLoyalty :: Natural.Natural -> ObjectId.ObjectId -> GameState.GameState -> GameState.GameState
withLoyalty loyalty oid gs = gs {GameState.objects = Map.adjust (\o -> o {Object.counters = Map.singleton CounterKind.Loyalty loyalty}) oid (GameState.objects gs)}

-- Space Beleren's three loyalty abilities, in printed order.
withAbilities :: (Monad m) => Spec.Spec m n -> Registry.Registry m -> ((Ability, Ability, Ability) -> m ()) -> m ()
withAbilities s registry k = do
  beleren <- S.printingOf s registry "Space Beleren"
  case Face.activatedAbilities (S.combinedFace beleren) of
    [plus1, minus1, minus5] -> k (plus1, minus1, minus5)
    _ -> Spec.assertFailure s "Space Beleren should print three loyalty abilities"

type Ability = ActivatedAbility.ActivatedAbility Card.Card (GrantedAbility.GrantedAbility Card.Card)

sectorsOf :: ObjectId.ObjectId -> GameState.GameState -> [Designation.Designation]
sectorsOf oid gs = foldMap (Set.toList . Sector.sectorsIn . Object.designations) (Game.lookupObject oid gs)

plusCounters :: ObjectId.ObjectId -> GameState.GameState -> Integer
plusCounters oid gs = maybe 0 (toInteger . Map.findWithDefault 0 CounterKind.PlusOnePlusOne . Object.counters) (Game.lookupObject oid gs)

onBattlefield :: ObjectId.ObjectId -> GameState.GameState -> Bool
onBattlefield oid gs = oid `elem` GameState.battlefield gs
