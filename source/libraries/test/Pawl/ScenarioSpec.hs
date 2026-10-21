-- Covers Pawl.Scenario: what placing a board guarantees and what it does not,
-- how an entry is keyed to a moment and matched to a prompt, when a check runs,
-- and which scenario mistakes are reported rather than silently absorbed. The
-- scenarios under data/scenarios are its gameplay-level cases.
module Pawl.ScenarioSpec where

import qualified Control.Exception as Exception
import qualified Control.Monad.IO.Class as MonadIO
import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.ByteString as ByteString
import qualified Data.List as List
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Data.Text.Encoding as Encoding
import qualified Pawl.Codec.Scenario as Codec.Scenario
import qualified Pawl.Engine.Binding as Binding
import qualified Pawl.Engine.Engine as Engine
import qualified Pawl.Engine.Game as Game
import qualified Pawl.Exceptions.InvalidCorpus as InvalidCorpus
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.JsonSchema.Define as Define
import qualified Pawl.JsonSchema.Validate as Validate
import qualified Pawl.Registry as Registry
import qualified Pawl.Scenario as Scenario
import qualified Pawl.Scenario.Load as Load
import qualified Pawl.Spec as Spec
import qualified Pawl.Support as S
import qualified Pawl.Types.Action as A
import qualified Pawl.Types.Answer as Answer
import qualified Pawl.Types.Board as Board
import qualified Pawl.Types.CandidateCost as CandidateCost
import qualified Pawl.Types.CardName as CardName
import qualified Pawl.Types.Choices as Choices
import qualified Pawl.Types.Concession as Concession
import qualified Pawl.Types.Cost as Cost
import qualified Pawl.Types.Decider as Decider
import qualified Pawl.Types.Facing as Facing
import qualified Pawl.Types.GameState as GameState
import qualified Pawl.Types.Label as Label
import qualified Pawl.Types.ManaCost as ManaCost
import qualified Pawl.Types.ModeIndex as ModeIndex
import qualified Pawl.Types.ModeSelection as ModeSelection
import qualified Pawl.Types.Move as Move
import qualified Pawl.Types.ObjectId as ObjectId
import qualified Pawl.Types.Placement as Placement
import qualified Pawl.Types.Prompt as Prompt
import qualified Pawl.Types.Readiness as Readiness
import qualified Pawl.Types.Recipient as Recipient
import qualified Pawl.Types.Reply as Reply
import qualified Pawl.Types.Scenario as Scenario.Type
import qualified Pawl.Types.ScenarioFailure as ScenarioFailure
import qualified Pawl.Types.Seat as Seat
import qualified Pawl.Types.SlotName as SlotName
import qualified Pawl.Types.Staged as Staged
import qualified Pawl.Types.TapState as TapState
import qualified Pawl.Types.TeamId as TeamId
import qualified Pawl.Types.When as When
import qualified System.Directory as Directory

spec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
spec s registry = Spec.describe s "Scenario" $ do
  Spec.it s "a board is structurally coherent but not implicitly settled" $ do
    let piker = CardName.MkCardName (Text.pack "Goblin Piker")
        attacker =
          (S.objectSetup piker)
            { Placement.label = Just (Label.MkLabel (Text.pack "attacker")),
              Placement.damage = 1,
              Placement.readiness = Readiness.Ready
            }
        alice =
          (S.playerSetup S.alice)
            { Seat.battlefield = Seq.singleton attacker
            }
        setup = S.board (alice NonEmpty.:| [S.playerSetup S.bob]) S.alice S.beginningOfCombat
    result <- Scenario.stage registry setup
    case result of
      Left failure -> Spec.assertFailure s (S.renderFailure failure)
      Right built -> do
        let raw = Staged.state built
            settled = S.runPure S.identityAnswer raw Engine.settleForPriority
        Spec.assertEqWith s "the raw board still has its lethally damaged creature" (S.creaturesInPlay S.alice raw) 1
        Spec.assertEqWith s "construction emitted no history" (S.eventsOf raw) []
        Spec.assertEqWith s "explicit settlement removes it" (S.creaturesInPlay S.alice settled) 0

  Spec.it s "duplicate aliases are rejected" $ do
    let same = S.aliased "same" (S.permanent "Goblin Piker")
        alice = (S.playerSetup S.alice) {Seat.battlefield = Seq.fromList [same, same]}
        setup = S.board (alice NonEmpty.:| [S.playerSetup S.bob]) S.alice S.precombatMain
    result <- Scenario.stage registry setup
    Spec.assertEqWith s "duplicate alias" result (Left (ScenarioFailure.MkDuplicateLabel (Label.MkLabel (Text.pack "same"))))

  Spec.it s "CR 809.2 an emperor seat on no team is rejected" $ do
    let alice = (S.playerSetup S.alice) {Seat.emperor = True}
        setup = S.board (alice NonEmpty.:| [S.playerSetup S.bob]) S.alice S.precombatMain
    result <- Scenario.stage registry setup
    Spec.assertEqWith s "teamless emperor" result (Left (ScenarioFailure.MkIllegalEmperor (Label.MkLabel (Text.pack "alice"))))

  Spec.it s "CR 810.4 teammates showing different life totals on a shared-life board are rejected" $ do
    let alice = (S.playerSetup S.alice) {Seat.team = Just (TeamId.MkTeamId 1), Seat.life = 7}
        bob = (S.playerSetup S.bob) {Seat.team = Just (TeamId.MkTeamId 1)}
        setup = (S.board (alice NonEmpty.:| [bob]) S.alice S.precombatMain) {Board.sharedTeamLife = True}
    result <- Scenario.stage registry setup
    Spec.assertEqWith s "unshared life" result (Left (ScenarioFailure.MkUnsharedLife (Label.MkLabel (Text.pack "alice"))))

  Spec.it s "CR 111.7 a token placed off the battlefield is rejected" $ do
    let token = (S.permanent "Goblin Piker") {Placement.token = True}
        alice = (S.playerSetup S.alice) {Seat.hand = Seq.singleton token}
        setup = S.board (alice NonEmpty.:| [S.playerSetup S.bob]) S.alice S.precombatMain
    result <- Scenario.stage registry setup
    Spec.assertEqWith s "token in hand" result (Left (ScenarioFailure.MkTokenOffBattlefield (CardName.MkCardName (Text.pack "Goblin Piker"))))

  Spec.it s "CR 712.8 a placement showing a face its card lacks is rejected" $ do
    let shown = (S.permanent "Goblin Piker") {Placement.face = Just (CardName.MkCardName (Text.pack "Nightfall Predator"))}
        alice = (S.playerSetup S.alice) {Seat.battlefield = Seq.singleton shown}
        setup = S.board (alice NonEmpty.:| [S.playerSetup S.bob]) S.alice S.precombatMain
    result <- Scenario.stage registry setup
    Spec.assertEqWith s "unknown face" result (Left (ScenarioFailure.MkUnknownFace (CardName.MkCardName (Text.pack "Goblin Piker")) (CardName.MkCardName (Text.pack "Nightfall Predator"))))

  Spec.it s "CR 310.9 a protector naming no seat is rejected" $ do
    let battle = (S.permanent "Invasion of Dominaria") {Placement.protector = Just (Label.MkLabel (Text.pack "carol"))}
        alice = (S.playerSetup S.alice) {Seat.battlefield = Seq.singleton battle}
        setup = S.board (alice NonEmpty.:| [S.playerSetup S.bob]) S.alice S.precombatMain
    result <- Scenario.stage registry setup
    Spec.assertEqWith s "unknown protector" result (Left (ScenarioFailure.MkUnknownProtector (Label.MkLabel (Text.pack "carol"))))

  Spec.it s "unreached scheduled entries fail" $ do
    let setup = S.duel S.precombatMain [] []
        script = S.turn 1 [S.on S.precombatMain S.alice (S.attack [])]
    built <- S.buildBoardOrFail s registry setup
    case Scenario.rehearse script built (pure ()) of
      Left (ScenarioFailure.MkUnreachedEntries _ _ entries) ->
        Spec.assertEqWith s "the unreached entry" entries script
      Left failure -> Spec.assertFailure s (S.renderFailure failure)
      Right _ -> Spec.assertFailure s "the unreached entry was silently ignored"

  Spec.it s "entries at the same moment are consumed in source order" $ do
    let setup =
          S.duel
            S.declareAttackers
            [S.settled "first" "Goblin Piker", S.settled "second" "Goblin Piker"]
            []
        script =
          S.turn
            1
            [ S.on S.declareAttackers S.alice (S.attack [S.aliasRef "first"]),
              S.on S.declareAttackers S.alice (S.attack [S.namedRef "Goblin Piker" 2])
            ]
    built <- S.buildBoardOrFail s registry setup
    case (Map.lookup (Label.MkLabel (Text.pack "first")) (Staged.objects built), Map.lookup (Label.MkLabel (Text.pack "second")) (Staged.objects built)) of
      (Just first, Just second) -> do
        let prompt = Prompt.DeclareAttackers (Decider.MkDecider S.alice) S.alice [first, second]
            askTwice = (,) <$> Game.ask prompt <*> Game.ask prompt
        case Scenario.rehearse script built askTwice of
          Left failure -> Spec.assertFailure s (S.renderFailure failure)
          Right (chosen, _) ->
            Spec.assertEqWith s "same-moment source order" chosen ([first], [second])
      _ -> Spec.assertFailure s "the board omitted an alias"

  Spec.it s "CR 723.5 a script is keyed on the decider, not the affected player" $ do
    -- alice decides for bob. An entry written under alice answers the prompt;
    -- one written under bob is never reached, because bob answers nothing.
    let setup = S.duel S.declareAttackers [S.settled "attacker" "Goblin Piker"] []
        attack = S.attack [S.aliasRef "attacker"]
    built <- S.buildBoardOrFail s registry setup
    case Map.lookup (Label.MkLabel (Text.pack "attacker")) (Staged.objects built) of
      Nothing -> Spec.assertFailure s "the board omitted an alias"
      Just attacker -> do
        let prompt = Prompt.DeclareAttackers (Decider.MkDecider S.alice) S.bob [attacker]
            ask = Game.ask prompt
        case Scenario.rehearse (S.turn 1 [S.on S.declareAttackers S.alice attack]) built ask of
          Left failure -> Spec.assertFailure s (S.renderFailure failure)
          Right (chosen, _) -> Spec.assertEqWith s "alice's entry answered bob's prompt" chosen [attacker]
        case Scenario.rehearse (S.turn 1 [S.on S.declareAttackers S.bob attack]) built ask of
          Left (ScenarioFailure.MkUnscheduledPrompt _ _ _ kind _) ->
            Spec.assertEqWith s "bob's entry answered nothing" kind (Text.pack "DeclareAttackers")
          Left failure -> Spec.assertFailure s (S.renderFailure failure)
          Right _ -> Spec.assertFailure s "an entry keyed on the affected player was consumed"

  Spec.it s "unoffered actions pass without consuming a later combat entry" $ do
    let setup = S.duel S.precombatMain [] []
        script = S.turn 1 [S.on S.precombatMain S.alice (S.attack [])]
    built <- S.buildBoardOrFail s registry setup
    let priority = do
          State.modify' (\gs -> gs {GameState.priority = Just S.alice})
          Engine.priorityLoop
    case Scenario.rehearse script built priority of
      Left (ScenarioFailure.MkUnreachedEntries _ _ entries) ->
        Spec.assertEqWith s "ChooseAction passed and left the combat entry alone" entries script
      Left failure -> Spec.assertFailure s (S.renderFailure failure)
      Right _ -> Spec.assertFailure s "the unrelated combat entry was consumed"

  Spec.it s "a scheduled cast is selected from the offered actions" $ do
    let spell = S.aliased "spell" (S.cardSetup "Goblin Piker")
        alice = S.hand S.alice [spell]
        setup = S.board (alice NonEmpty.:| [S.playerSetup S.bob]) S.alice S.precombatMain
        verb = S.castAction (S.aliasRef "spell") Choices.none
        script = S.turn 1 [S.on S.precombatMain S.alice verb]
    built <- S.buildBoardOrFail s registry setup
    case Map.lookup (Label.MkLabel (Text.pack "spell")) (Staged.objects built) of
      Nothing -> Spec.assertFailure s "the board omitted the hand alias"
      Just oid -> do
        let action = A.Cast oid (CardName.MkCardName (Text.pack "Goblin Piker")) Facing.FaceUp
            prompt = Prompt.ChooseAction (Decider.MkDecider S.alice) S.alice [A.Pass, action]
        case Scenario.rehearse script built (Game.ask prompt) of
          Left failure -> Spec.assertFailure s (S.renderFailure failure)
          Right (chosen, after) -> do
            Spec.assertEqWith s "the offered cast" chosen action
            Spec.assertEqWith s "answering emitted no history itself" (S.eventsOf after) []

  Spec.it s "a scheduled action that was not offered fails" $ do
    let spell = S.aliased "spell" (S.cardSetup "Goblin Piker")
        setup = S.board (S.hand S.alice [spell] NonEmpty.:| [S.playerSetup S.bob]) S.alice S.precombatMain
        verb = S.castAction (S.aliasRef "spell") Choices.none
        script = S.turn 1 [S.on S.precombatMain S.alice verb]
        prompt = Prompt.ChooseAction (Decider.MkDecider S.alice) S.alice [A.Pass]
    built <- S.buildBoardOrFail s registry setup
    case Scenario.rehearse script built (Game.ask prompt) of
      Left (ScenarioFailure.MkActionNotOffered _ failed _) ->
        Spec.assertEqWith s "the rejected verb" failed verb
      Left failure -> Spec.assertFailure s (S.renderFailure failure)
      Right _ -> Spec.assertFailure s "the unoffered cast was accepted"

  Spec.it s "an underspecified action that matches two offers fails" $ do
    let spell = S.aliased "spell" (S.cardSetup "Goblin Piker")
        setup = S.board (S.hand S.alice [spell] NonEmpty.:| [S.playerSetup S.bob]) S.alice S.precombatMain
        verb = S.castAction (S.aliasRef "spell") Choices.none
        script = S.turn 1 [S.on S.precombatMain S.alice verb]
    built <- S.buildBoardOrFail s registry setup
    case Map.lookup (Label.MkLabel (Text.pack "spell")) (Staged.objects built) of
      Nothing -> Spec.assertFailure s "the board omitted the hand alias"
      Just oid -> do
        let front = A.Cast oid (CardName.MkCardName (Text.pack "Goblin Piker")) Facing.FaceUp
            back = A.Cast oid (CardName.MkCardName (Text.pack "Goblin Piker Back")) Facing.FaceUp
            prompt = Prompt.ChooseAction (Decider.MkDecider S.alice) S.alice [front, back]
        case Scenario.rehearse script built (Game.ask prompt) of
          Left (ScenarioFailure.MkAmbiguousAction _ failed _) ->
            Spec.assertEqWith s "the ambiguous verb" failed verb
          Left failure -> Spec.assertFailure s (S.renderFailure failure)
          Right _ -> Spec.assertFailure s "the ambiguous cast was guessed"

  Spec.it s "attached choices are consumed by their action" $ do
    let spell = S.aliased "spell" (S.cardSetup "Goblin Piker")
        target = S.aliased "target" (S.permanent "Goblin Piker")
        alice = (S.hand S.alice [spell]) {Seat.battlefield = Seq.singleton target}
        setup = S.board (alice NonEmpty.:| [S.playerSetup S.bob]) S.alice S.precombatMain
        choices =
          Choices.none
            { Choices.targets = Just [S.aliasRef "target"],
              Choices.modes = Just (Seq.singleton (ModeIndex.MkModeIndex 1)),
              Choices.x = Just 3,
              Choices.cost = Just (ManaCost.MkManaCost [])
            }
        verb = S.castAction (S.aliasRef "spell") choices
        script = S.turn 1 [S.on S.precombatMain S.alice verb]
    built <- S.buildBoardOrFail s registry setup
    case (Map.lookup (Label.MkLabel (Text.pack "spell")) (Staged.objects built), Map.lookup (Label.MkLabel (Text.pack "target")) (Staged.objects built)) of
      (Just spellId, Just targetId) -> do
        let action = A.Cast spellId (CardName.MkCardName (Text.pack "Goblin Piker")) Facing.FaceUp
            actionPrompt = Prompt.ChooseAction (Decider.MkDecider S.alice) S.alice [A.Pass, action]
            mode = ModeIndex.MkModeIndex 1
            modePrompt = Prompt.ChooseModes (Decider.MkDecider S.alice) S.alice spellId (Set.singleton mode) (ModeSelection.ChooseExactly 1)
            xPrompt = Prompt.ChooseX (Decider.MkDecider S.alice) S.alice spellId Binding.variableX 0 9
            cost = Cost.MkCost {Cost.mana = Just (ManaCost.MkManaCost []), Cost.components = []}
            costPrompt = Prompt.ChooseCost (Decider.MkDecider S.alice) S.alice spellId [CandidateCost.plain Nothing cost]
            slot = SlotName.MkSlotName (Text.pack "target")
            targetPrompt =
              Prompt.ChooseTargets
                (Decider.MkDecider S.alice)
                S.alice
                spellId
                (Map.singleton slot (1, Set.singleton (Recipient.ToCreature targetId)))
            asks = (,,,,) <$> Game.ask actionPrompt <*> Game.ask modePrompt <*> Game.ask xPrompt <*> Game.ask costPrompt <*> Game.ask targetPrompt
        case Scenario.rehearse script built asks of
          Left failure -> Spec.assertFailure s (S.renderFailure failure)
          Right ((chosen, modes, x, chosenCost, targets), _) -> do
            Spec.assertEqWith s "the priority action" chosen action
            Spec.assertEqWith s "the action's modes" modes (Seq.singleton mode)
            Spec.assertEqWith s "the action's X" x 3
            Spec.assertEqWith s "the action's cost" chosenCost (CandidateCost.plain Nothing cost)
            Spec.assertEqWith s "the action's target" targets (Map.singleton slot (Set.singleton (Recipient.ToCreature targetId)))
      _ -> Spec.assertFailure s "the board omitted an action alias"

  Spec.it s "an unused attached choice fails" $ do
    let spell = S.aliased "spell" (S.cardSetup "Goblin Piker")
        setup = S.board (S.hand S.alice [spell] NonEmpty.:| [S.playerSetup S.bob]) S.alice S.precombatMain
        choices = Choices.none {Choices.x = Just 3}
        verb = S.castAction (S.aliasRef "spell") choices
        script = S.turn 1 [S.on S.precombatMain S.alice verb]
    built <- S.buildBoardOrFail s registry setup
    case Map.lookup (Label.MkLabel (Text.pack "spell")) (Staged.objects built) of
      Nothing -> Spec.assertFailure s "the board omitted the hand alias"
      Just oid -> do
        let action = A.Cast oid (CardName.MkCardName (Text.pack "Goblin Piker")) Facing.FaceUp
            prompt = Prompt.ChooseAction (Decider.MkDecider S.alice) S.alice [A.Pass, action]
        case Scenario.rehearse script built (Game.ask prompt) of
          Left (ScenarioFailure.MkUnusedActionChoices _ failed _) ->
            Spec.assertEqWith s "the unfinished verb" failed verb
          Left failure -> Spec.assertFailure s (S.renderFailure failure)
          Right _ -> Spec.assertFailure s "the unused X was ignored"

  Spec.it s "a leftover choice fails at the next prompt rather than answering it" $ do
    let spell = S.aliased "spell" (S.cardSetup "Goblin Piker")
        setup = S.board (S.hand S.alice [spell] NonEmpty.:| [S.playerSetup S.bob]) S.alice S.precombatMain
        choices = Choices.none {Choices.manaSources = Seq.singleton Nothing}
        verb = S.castAction (S.aliasRef "spell") choices
        script = S.turn 1 [S.on S.precombatMain S.alice verb]
    built <- S.buildBoardOrFail s registry setup
    case Map.lookup (Label.MkLabel (Text.pack "spell")) (Staged.objects built) of
      Nothing -> Spec.assertFailure s "the board omitted the hand alias"
      Just oid -> do
        let action = A.Cast oid (CardName.MkCardName (Text.pack "Goblin Piker")) Facing.FaceUp
            prompt = Prompt.ChooseAction (Decider.MkDecider S.alice) S.alice [A.Pass, action]
        case Scenario.rehearse script built (Game.ask prompt *> Game.ask prompt) of
          Left (ScenarioFailure.MkUnusedActionChoices _ failed _) ->
            Spec.assertEqWith s "the unfinished verb" failed verb
          Left failure -> Spec.assertFailure s (S.renderFailure failure)
          Right _ -> Spec.assertFailure s "the leftover mana source was carried into the next priority"

  Spec.it s "another decider's sub-choice is not answered from the pending action" $ do
    let spell = S.aliased "spell" (S.cardSetup "Goblin Piker")
        setup = S.board (S.hand S.alice [spell] NonEmpty.:| [S.playerSetup S.bob]) S.alice S.precombatMain
        choices = Choices.none {Choices.x = Just 3}
        verb = S.castAction (S.aliasRef "spell") choices
        script = S.turn 1 [S.on S.precombatMain S.alice verb]
    built <- S.buildBoardOrFail s registry setup
    case Map.lookup (Label.MkLabel (Text.pack "spell")) (Staged.objects built) of
      Nothing -> Spec.assertFailure s "the board omitted the hand alias"
      Just oid -> do
        let action = A.Cast oid (CardName.MkCardName (Text.pack "Goblin Piker")) Facing.FaceUp
            actionPrompt = Prompt.ChooseAction (Decider.MkDecider S.alice) S.alice [A.Pass, action]
            xPrompt = Prompt.ChooseX (Decider.MkDecider S.bob) S.bob oid Binding.variableX 0 9
        case Scenario.rehearse script built (Game.ask actionPrompt *> Game.ask xPrompt) of
          Left (ScenarioFailure.MkUnusedActionChoices _ failed _) ->
            Spec.assertEqWith s "the unfinished verb" failed verb
          Left failure -> Spec.assertFailure s (S.renderFailure failure)
          Right _ -> Spec.assertFailure s "bob's X was answered from alice's cast"

  Spec.it s "an action queued behind an unreached entry is still taken" $ do
    let land = S.aliased "land" (S.cardSetup "Mountain")
        setup = S.board (S.hand S.alice [land] NonEmpty.:| [S.playerSetup S.bob]) S.alice S.precombatMain
        stranded = S.on S.precombatMain S.alice (S.attack [])
        script = S.turn 1 [stranded, S.on S.precombatMain S.alice (S.playLand (S.aliasRef "land"))]
    built <- S.buildBoardOrFail s registry setup
    case Map.lookup (Label.MkLabel (Text.pack "land")) (Staged.objects built) of
      Nothing -> Spec.assertFailure s "the board omitted the hand alias"
      Just oid -> do
        let action = A.Play oid Nothing
            prompt = Prompt.ChooseAction (Decider.MkDecider S.alice) S.alice [A.Pass, action]
        case Scenario.rehearse script built (Game.ask prompt) of
          Left (ScenarioFailure.MkUnreachedEntries _ _ entries) ->
            Spec.assertEqWith s "only the stranded entry remains" entries (S.turn 1 [stranded])
          Left failure -> Spec.assertFailure s (S.renderFailure failure)
          Right _ -> Spec.assertFailure s "the stranded entry was consumed"

  Spec.it s "a scheduled defender must be offered" $ do
    let setup = S.board (S.playerSetup S.alice NonEmpty.:| [S.playerSetup S.bob, S.playerSetup S.carol]) S.alice S.beginningOfCombat
        verb = S.chooseDefender S.carol
        script = S.turn 1 [S.on S.beginningOfCombat S.alice verb]
        prompt = Prompt.ChooseDefender (Decider.MkDecider S.alice) S.alice (S.bob NonEmpty.:| [S.carol])
    built <- S.buildBoardOrFail s registry setup
    case Scenario.rehearse script built (Game.ask prompt) of
      Left failure -> Spec.assertFailure s (S.renderFailure failure)
      Right (chosen, _) -> Spec.assertEqWith s "the named defender" chosen S.carol

  Spec.it s "concession is opt-in at its scheduled moment" $ do
    let setup = S.duel S.precombatMain [] []
        concede = S.turn 1 [S.on S.precombatMain S.alice Move.Concede]
    built <- S.buildBoardOrFail s registry setup
    case Scenario.rehearse concede built (Game.ask (Prompt.Concede S.alice)) of
      Left failure -> Spec.assertFailure s (S.renderFailure failure)
      Right (answer, _) ->
        Spec.assertEqWith s "scheduled concession" answer Concession.Concedes

  Spec.it s "an unscheduled non-action prompt fails" $ do
    let setup = S.duel S.beginningOfCombat [S.ready (S.permanent "Goblin Piker")] []
    built <- S.buildBoardOrFail s registry setup
    case Scenario.rehearse Seq.empty built S.combatGame of
      Left (ScenarioFailure.MkUnscheduledPrompt _ _ _ kind _) ->
        Spec.assertEqWith s "the prompt kind" kind (Text.pack "DeclareAttackers")
      Left failure -> Spec.assertFailure s (S.renderFailure failure)
      Right _ -> Spec.assertFailure s "the attackers prompt was silently answered"

  Spec.it s "a board past the beginning of combat can attack" $ do
    -- CR 506.2 / CR 703.4h: the defending player is settled during the beginning
    -- of combat step, so a board positioned AFTER it has to arrive with that
    -- done. Without it Combat.declareAttackers finds no defending player, skips
    -- its prompt, and the attack entry reports itself as never reached.
    let setup = S.duel S.declareAttackers [S.settled "attacker" "Goblin Piker"] []
        script = S.turn 1 [S.on S.declareAttackers S.alice (S.attack [S.aliasRef "attacker"])]
    after <- S.play s registry setup script S.combatGame
    Spec.assertEqWith s "bob took the attacker's two" (S.lifeOf S.bob after) (Just 18)

  Spec.it s "a reference the prompt did not offer is a failure, not a dropped entry" $ do
    -- Both Pikers are alice's, so "Goblin Piker" resolves; only the untapped
    -- one is a legal attacker (CR 508.1a), so the prompt never offers the first.
    -- The engine would filter it out AFTER the entry was popped, leaving a green
    -- script with nobody attacking.
    let tapped = (S.ready (S.permanent "Goblin Piker")) {Placement.tapped = TapState.Tapped}
        setup = S.duel S.declareAttackers [tapped, S.ready (S.permanent "Goblin Piker")] []
        script = S.turn 1 [S.on S.declareAttackers S.alice (S.attack [S.namedRef "Goblin Piker" 1])]
    built <- S.buildBoardOrFail s registry setup
    case Scenario.rehearse script built S.combatGame of
      Left (ScenarioFailure.MkUnofferedObject _ kind named offers) -> do
        Spec.assertEqWith s "the unoffered reference" named (Text.pack "Goblin Piker")
        Spec.assertEqWith s "the prompt it came from" kind (Text.pack "DeclareAttackers")
        Spec.assertEqWith s "what it did offer" offers [Text.pack "Goblin Piker#2"]
      Left failure -> Spec.assertFailure s (S.renderFailure failure)
      Right _ -> Spec.assertFailure s "the unoffered attacker was silently dropped"

  -- Two settled Forests, and CR 601.2g's window offering the first alone, as
  -- Pawl.Engine.Interchangeable has it offer one of two identical sources. The
  -- engine reads a source it did not offer as a decline
  -- (Pawl.Engine.Cost.chooseSource), so a script naming the second would pass on
  -- that decline rather than on the tap it wrote.
  Spec.it s "an Answer naming a mana source the prompt did not offer is a failure" $ do
    outcome <- manaSourceAnswer s registry "$f2" False
    case outcome of
      Left (ScenarioFailure.MkUnofferedAnswer _ _ kind) ->
        Spec.assertEqWith s "the prompt it answered" kind (Text.pack "ChooseManaSource")
      Left failure -> Spec.assertFailure s (S.renderFailure failure)
      Right _ -> Spec.assertFailure s "the unoffered source passed as a decline"

  Spec.it s "an Answer flagged unoffered reaches the engine" $ do
    outcome <- manaSourceAnswer s registry "$f2" True
    case outcome of
      Left failure -> Spec.assertFailure s (S.renderFailure failure)
      Right (chosen, second) -> Spec.assertEqWith s "the unoffered source, as written" chosen (Just second)

  Spec.it s "an Answer flagged unoffered that the prompt offers is a failure" $ do
    outcome <- manaSourceAnswer s registry "$f1" True
    case outcome of
      Left (ScenarioFailure.MkOfferedAnswer _ _ kind) ->
        Spec.assertEqWith s "the prompt it answered" kind (Text.pack "ChooseManaSource")
      Left failure -> Spec.assertFailure s (S.renderFailure failure)
      Right _ -> Spec.assertFailure s "a flag the answer contradicts passed"

  Spec.it s "a qualified assignment is matched by its source, not by its position" $ do
    -- Two double-blocked attackers are prompted in the engine's order over
    -- Combat.attackers, which the script does not know. The assignments are
    -- listed in the opposite order on purpose: matching by position answers the
    -- first prompt with the second attacker's map.
    let setup =
          S.duel
            S.beginningOfCombat
            [S.settled "left" "Goblin Piker", S.settled "right" "Goblin Piker"]
            [ S.settled "left first" "Goblin Piker",
              S.settled "left second" "Goblin Piker",
              S.settled "right first" "Goblin Piker",
              S.settled "right second" "Goblin Piker"
            ]
        left = S.aliasRef "left"
        right = S.aliasRef "right"
        script =
          S.turn
            1
            [ S.on S.declareAttackers S.alice (S.attack [left, right]),
              S.on
                S.declareBlockers
                S.bob
                ( S.block
                    [ (S.aliasRef "left first", left),
                      (S.aliasRef "left second", left),
                      (S.aliasRef "right first", right),
                      (S.aliasRef "right second", right)
                    ]
                ),
              S.onSource
                S.combatDamage
                S.alice
                right
                ( S.assignDamage
                    [ (S.aliasRef "right first", 1),
                      (S.aliasRef "right second", 1)
                    ]
                ),
              S.onSource
                S.combatDamage
                S.alice
                left
                ( S.assignDamage
                    [ (S.aliasRef "left first", 1),
                      (S.aliasRef "left second", 1)
                    ]
                )
            ]
    fought <- S.play s registry setup script S.combatGame
    -- Each Piker is a 2/1, so one point is lethal: every blocker dies.
    Spec.assertEqWith s "all four blockers were assigned lethal damage" (S.creaturesInPlay S.bob (S.settleSba fought)) 0

  Spec.it s "a qualifier on a prompt with no source is a script error" $ do
    let attacker = S.aliasRef "attacker"
        setup = S.duel S.declareAttackers [S.settled "attacker" "Goblin Piker"] []
        script = S.turn 1 [S.onSource S.declareAttackers S.alice attacker (S.attack [attacker])]
    built <- S.buildBoardOrFail s registry setup
    case Scenario.rehearse script built S.combatGame of
      Left (ScenarioFailure.MkUnexpectedQualifier _ kind ref) -> do
        Spec.assertEqWith s "the prompt that has no source" kind (Text.pack "DeclareAttackers")
        Spec.assertEqWith s "the qualifier it carried" ref attacker
      Left failure -> Spec.assertFailure s (S.renderFailure failure)
      Right _ -> Spec.assertFailure s "the dangling qualifier was ignored"

  -- CR 733.1: a refused move is one the engine reverses and asks for again, so
  -- a legal declaration under `refuse` stands and fails the run.
  Spec.it s "a refused move that stands fails, naming the prompt asked next" $ do
    result <-
      runJson
        s
        registry
        ( "{\"description\":\"x\",\"board\":{\"seats\":[{\"name\":\"alice\",\"battlefield\":[{\"card\":\"Goblin Piker\",\"label\":\"attacker\",\"ready\":true}]},{\"name\":\"bob\",\"battlefield\":[{\"card\":\"Goblin Piker\",\"ready\":true}]}],\"active\":\"alice\",\"step\":\"DeclareAttackers\"},"
            <> "\"timeline\":[{\"turn\":1,\"step\":\"DeclareAttackers\",\"player\":\"alice\",\"do\":{\"Attack\":[\"$attacker\"]}},"
            <> "{\"turn\":1,\"step\":\"DeclareBlockers\",\"player\":\"bob\",\"refuse\":{\"Block\":{}}}]}"
        )
    case result of
      Left (ScenarioFailure.MkUnrefusedMove key verb next) -> do
        Spec.assertEqWith s "the moment it answered" key (When.MkWhen 1 S.declareBlockers (S.seatLabel S.bob))
        Spec.assertEqWith s "the move that stood" verb (Move.Block Map.empty)
        Spec.assertBool s (next /= Just (Text.pack "DeclareBlockers")) "the declaration was asked again"
      Left failure -> Spec.assertFailure s (S.renderFailure failure)
      Right _ -> Spec.assertFailure s "a declaration that stood passed as refused"

  -- CR 601.2e / 733.1: a cast the engine finds illegal is reversed, so a script
  -- whose cast is taken and then rejected fails rather than passing on a game
  -- in which nothing was cast. Convoking five creatures for the Loxodon's {4}{W}
  -- is a tap its cost has no room for.
  Spec.it s "a taken cast the engine reverses fails, naming the cast" $ do
    result <- runJson s registry (convokeLoxodon ["$p1", "$p2", "$p3", "$p4", "$guard"])
    case result of
      Left (ScenarioFailure.MkUnmadeMove key verb) -> do
        Spec.assertEqWith s "the moment it was taken" key (When.MkWhen 1 S.precombatMain (S.seatLabel S.alice))
        Spec.assertBool s (case verb of Move.Cast {} -> True; _ -> False) "the move named is the cast"
      Left failure -> Spec.assertFailure s (S.renderFailure failure)
      Right _ -> Spec.assertFailure s "the reversed cast passed with the Loxodon still in hand"

  Spec.it s "the same cast convoking four creatures is made" $ do
    result <- runJson s registry (convokeLoxodon ["$p1", "$p2", "$p3", "$p4"])
    case result of
      Left failure -> Spec.assertFailure s (S.renderFailure failure)
      Right final -> Spec.assertEqWith s "the Loxodon resolved" (S.countOnBattlefieldByName (CardName.MkCardName (Text.pack "Venerated Loxodon")) S.alice final) 1

  -- CR 406.3a: a foretold card is turned face up before its cast is announced,
  -- and stays so when the cast is reversed (CR 601.2e), so the game does not look
  -- as the move found it. One floating {U} is short of the foretell cost {1}{U}.
  Spec.it s "a reversed cast of a card exiled face down fails" $ do
    result <- runJson s registry (castForetold True)
    case result of
      Left (ScenarioFailure.MkUnmadeMove key verb) -> do
        Spec.assertEqWith s "the moment it was taken" key (When.MkWhen 3 S.precombatMain (S.seatLabel S.alice))
        Spec.assertBool s (case verb of Move.Cast {} -> True; _ -> False) "the move named is the cast"
      Left failure -> Spec.assertFailure s (S.renderFailure failure)
      Right _ -> Spec.assertFailure s "the reversed cast passed with the Raven still in exile"

  Spec.it s "the same foretold card paid in full is cast" $ do
    result <- runJson s registry (castForetold False)
    case result of
      Left failure -> Spec.assertFailure s (S.renderFailure failure)
      Right final -> Spec.assertEqWith s "the Raven resolved" (S.countOnBattlefieldByName (CardName.MkCardName (Text.pack "Augury Raven")) S.alice final) 1

  -- CR 702.122a / 733.1: a crew activation whose taps fall short of crew 6 is
  -- reversed, which leaves the game as the move found it.
  Spec.it s "a taken activation the engine reverses fails, naming it" $ do
    result <- runJson s registry (crewDreadnought ["$giant"])
    case result of
      Left (ScenarioFailure.MkUnmadeMove _ verb) ->
        Spec.assertBool s (case verb of Move.Activate {} -> True; _ -> False) "the move named is the activation"
      Left failure -> Spec.assertFailure s (S.renderFailure failure)
      Right _ -> Spec.assertFailure s "the reversed crew passed with nothing tapped"

  Spec.it s "the same crew tapping both giants is made" $ do
    result <- runJson s registry (crewDreadnought ["$giant", "$blind"])
    case result of
      Left failure -> Spec.assertFailure s (S.renderFailure failure)
      Right _ -> pure ()

  -- CR 510.1c-d: the engine deals nothing for an assignment that does not divide
  -- the creature's power, so a script writing one fails rather than passing
  -- on a combat in which no damage was dealt.
  Spec.it s "an assignment that does not divide the power is a failure" $ do
    result <- runJson s registry (doubleBlocked "{\"$first\":2,\"$second\":2}")
    case result of
      Left (ScenarioFailure.MkUnofferedAnswer _ verb kind) -> do
        Spec.assertEqWith s "the prompt it answered" kind (Text.pack "AssignCombatDamage")
        Spec.assertBool s (case verb of Move.AssignDamage {} -> True; _ -> False) "the move named is the assignment"
      Left failure -> Spec.assertFailure s (S.renderFailure failure)
      Right _ -> Spec.assertFailure s "the ill-divided assignment passed, dealing nothing"

  Spec.it s "the same attacker dividing its power is answered" $ do
    result <- runJson s registry (doubleBlocked "{\"$first\":1,\"$second\":1}")
    case result of
      Left failure -> Spec.assertFailure s (S.renderFailure failure)
      Right final -> Spec.assertEqWith s "both blockers died" (S.countOnBattlefieldByName (CardName.MkCardName (Text.pack "Goblin Piker")) S.bob final) 0

  -- CR 733.1 / 118.12a: a payment that fails is reversed, which returns its
  -- payer to the choice, so a script that wrote only the failing payment fails
  -- rather than passing on a spell countered as if bob had declined.
  Spec.it s "a failed Mana Leak payment is asked again, failing the script" $ do
    result <- runJson s registry leakUnpaid
    case result of
      Left (ScenarioFailure.MkUnscheduledPrompt _ _ decider kind _) -> do
        Spec.assertEqWith s "the prompt asked again" kind (Text.pack "ChooseToPay")
        Spec.assertEqWith s "of the payer" decider (Just (S.seatLabel S.bob))
      Left failure -> Spec.assertFailure s (S.renderFailure failure)
      Right _ -> Spec.assertFailure s "the failed payment passed as a decline"

  -- CR 510.1e / 702.19b: a trampler's assignment short of lethal on its blocker
  -- is illegal, and the engine asks for it again, so a script that wrote only
  -- that assignment fails rather than passing on a combat that dealt nothing.
  Spec.it s "a trample assignment short of lethal is asked again, failing the script" $ do
    result <- runJson s registry trampleShort
    case result of
      Left (ScenarioFailure.MkUnscheduledPrompt _ step decider kind _) -> do
        Spec.assertEqWith s "the prompt asked again" kind (Text.pack "AssignCombatDamage")
        Spec.assertEqWith s "in the combat damage step" step S.combatDamage
        Spec.assertEqWith s "of the attacker's controller" decider (Just (S.seatLabel S.alice))
      Left failure -> Spec.assertFailure s (S.renderFailure failure)
      Right _ -> Spec.assertFailure s "the short assignment passed, dealing nothing"

  -- The two ways a check can fail are never spelled alike: one that ran and
  -- read false, and one whose moment never came and so asserted nothing.
  Spec.it s "a check that reads false fails as a false check, naming what it saw" $ do
    result <- runJson s registry (attackThen "{\"turn\":1,\"step\":\"EndOfCombat\",\"player\":\"alice\",\"check\":{\"Life\":{\"player\":\"bob\",\"life\":17}}}" "[]")
    case result of
      Left (ScenarioFailure.MkCheckFailed (Just key) _ observed) -> do
        Spec.assertEqWith s "the moment it ran at" key (When.MkWhen 1 S.endOfCombat (S.seatLabel S.alice))
        Spec.assertEqWith s "what it saw" observed (Text.pack "18")
      Left failure -> Spec.assertFailure s (S.renderFailure failure)
      Right _ -> Spec.assertFailure s "a false check passed"

  Spec.it s "a check whose moment never comes fails as unrun, not as false" $ do
    -- CR 514.3: no player receives priority in the cleanup step, so a check
    -- waiting for alice's priority there never runs.
    result <- runJson s registry (attackThen "{\"turn\":1,\"step\":\"Cleanup\",\"player\":\"alice\",\"check\":{\"Life\":{\"player\":\"bob\",\"life\":18}}}" "[]")
    case result of
      Left (ScenarioFailure.MkUnrunChecks _ _ entries) -> Spec.assertEqWith s "the unrun check" (length entries) 1
      Left failure -> Spec.assertFailure s (S.renderFailure failure)
      Right _ -> Spec.assertFailure s "an unrun check passed"

  Spec.it s "a final check runs where the run stopped, once the timeline is spent" $ do
    -- The attack is the last entry, so the run stops after the declare
    -- attackers step, before any damage: bob is still at 20 there.
    result <- runJson s registry (attackThen "" "[{\"Life\":{\"player\":\"bob\",\"life\":18}}]")
    case result of
      Left (ScenarioFailure.MkCheckFailed Nothing _ observed) -> Spec.assertEqWith s "bob before damage" observed (Text.pack "20")
      Left failure -> Spec.assertFailure s (S.renderFailure failure)
      Right _ -> Spec.assertFailure s "the final check read a state past the run's end"

  Spec.it s "a label naming a seat is not an object" $ do
    result <- runJson s registry (attackThenAttacking "$bob")
    case result of
      Left (ScenarioFailure.MkNotAnObject _) -> pure ()
      Left failure -> Spec.assertFailure s (S.renderFailure failure)
      Right _ -> Spec.assertFailure s "a seat was declared as an attacker"

-- Every scenario under data/scenarios: each file matches the schema pawl
-- emits for it, and runs clean.
-- The corpus is one directory per source spec, so a root's scenarios are every
-- .json file beneath it, ascending by path.
loadSpec :: Spec.Spec IO n -> n ()
loadSpec s = Spec.describe s "Pawl.Scenario.Load" $ do
  Spec.it s "listRoot finds scenarios in subdirectories, ascending by path" $ do
    found <- S.withCorpusDir "scenario-load-nested" [("b.json", Text.pack "{}"), ("notes.txt", Text.empty)] $ \dir -> do
      Directory.createDirectoryIfMissing True (dir <> "/sub")
      ByteString.writeFile (dir <> "/sub/a.json") (Encoding.encodeUtf8 (Text.pack "{}"))
      listed <- Load.listRoot dir
      pure (fmap (drop (length dir)) listed)
    Spec.assertEqWith s "both .json files, the nested one included" found ["/b.json", "/sub/a.json"]

-- A run looks up the cards it places and the names the engine asks, nothing
-- else: over a root holding a malformed file, a lookup that misses reaches
-- that file (Pawl.Registry.fileRegistry's whole-root fallback) and throws
-- InvalidCorpus. The board places Goblin Piker; every other string (seats,
-- steps, zones, a label, a card the final check counts) is no card the pool
-- holds, and looking any of them up would throw. The control places a card no
-- file holds, whose lookup misses and so reaches the file.
referenceSpec :: Spec.Spec IO n -> n ()
referenceSpec s = Spec.describe s "Scenario reference" $ do
  Spec.it s "a run looks up only the cards its scenario names" $ do
    piker <- S.pikerJson
    let scenario card =
          "{\"description\":\"x\",\"board\":{\"seats\":[{\"name\":\"alice\",\"battlefield\":[{\"card\":\""
            <> card
            <> "\",\"label\":\"piker\"}]},{\"name\":\"bob\"}],\"active\":\"alice\",\"step\":\"PrecombatMain\"},"
            <> "\"timeline\":[{\"turn\":1,\"step\":\"PrecombatMain\",\"player\":\"alice\",\"check\":{\"Count\":{\"player\":\"alice\",\"zone\":\"Battlefield\",\"card\":\""
            <> card
            <> "\",\"count\":1}}}],\"final\":[{\"Count\":{\"player\":\"bob\",\"zone\":\"Graveyard\",\"card\":\"Lightning Bolt\",\"count\":0}}]}"
        attempt registry card = Exception.try (runJson s registry (scenario card)) :: IO (Either InvalidCorpus.InvalidCorpus (Either ScenarioFailure.ScenarioFailure GameState.GameState))
    S.withCorpusDir "scenario-reference" [("goblin-piker.json", piker), ("bird-maiden.json", Text.pack "{oh no")] $ \dir -> do
      registry <- Registry.fileRegistry dir
      named <- attempt registry "Goblin Piker"
      case named of
        Left err -> Spec.assertFailure s ("a run naming only Goblin Piker reached the malformed file: " <> show err)
        Right (Left failure) -> Spec.assertFailure s ("the run failed: " <> S.renderFailure failure)
        Right (Right _) -> pure ()
      missing <- attempt registry "Goblin Pikers"
      case missing of
        Left err -> Spec.assertEqWith s "the control's miss reaches the malformed file" (fmap (List.isInfixOf "bird-maiden.json") (InvalidCorpus.problems err)) [True]
        Right _ -> Spec.assertFailure s "the control's miss should reach the malformed file"

corpusSpec :: (MonadIO.MonadIO n) => Spec.Spec IO n -> Registry.Registry IO -> n ()
corpusSpec s registry = Spec.describe s "Scenarios" $ do
  -- Listed, not decoded: each case is named for its file and decodes it in its
  -- body, so building the test tree reads no scenario.
  root <- MonadIO.liftIO Load.defaultRoot
  paths <- MonadIO.liftIO (Load.listRoot root)
  mapM_ (scenarioCase s registry) paths

scenarioCase :: Spec.Spec IO n -> Registry.Registry IO -> FilePath -> n ()
scenarioCase s registry path =
  Spec.it s (reverse (takeWhile (/= '/') (reverse path))) $ do
    bytes <- ByteString.readFile path
    case Encoding.decodeUtf8' bytes of
      Left problem -> Spec.assertFailure s (path <> ": " <> show problem)
      Right contents -> case Common.parse contents of
        Left problem -> Spec.assertFailure s (path <> ": " <> Text.unpack problem)
        Right value -> Spec.assertEqWith s (path <> ": matches the scenario schema") (Validate.validate (Define.run (Codec.schema Codec.Scenario.codec)) value) []
    case Load.parse bytes of
      Left problem -> Spec.assertFailure s (path <> ": " <> Text.unpack problem)
      Right scenario -> do
        result <- Scenario.run registry scenario
        case result of
          Left failure -> Spec.assertFailure s (path <> ": " <> Text.unpack (Scenario.Type.description scenario) <> ": " <> S.renderFailure failure)
          Right _ -> pure ()

-- One scenario decoded and run, failing the case if it will not decode.
runJson :: (Monad m) => Spec.Spec m n -> Registry.Registry m -> String -> m (Either ScenarioFailure.ScenarioFailure GameState.GameState)
runJson s registry json = case Common.parse (Text.pack json) >>= Codec.decode Codec.Scenario.codec of
  Left problem -> Spec.assertFailure s (Text.unpack problem)
  Right scenario -> Scenario.run registry scenario

-- alice casts Venerated Loxodon at once, convoking `taps` from four Goblin
-- Pikers and a Palace Guard.
convokeLoxodon :: [String] -> String
convokeLoxodon taps =
  let ready label card = "{\"card\":\"" <> card <> "\",\"label\":\"" <> label <> "\",\"ready\":true}"
      creatures = [ready ("p" <> show n) "Goblin Piker" | n <- [1 :: Int .. 4]] <> [ready "guard" "Palace Guard"]
   in "{\"description\":\"x\",\"board\":{\"seats\":[{\"name\":\"alice\",\"battlefield\":["
        <> List.intercalate "," creatures
        <> "],\"hand\":[{\"card\":\"Venerated Loxodon\",\"label\":\"lox\"}]},{\"name\":\"bob\"}],\"active\":\"alice\",\"step\":\"PrecombatMain\"},"
        <> "\"timeline\":[{\"turn\":1,\"step\":\"PrecombatMain\",\"player\":\"alice\",\"do\":{\"Answer\":{\"prompt\":\"ChooseTaps\",\"with\":["
        <> List.intercalate "," (fmap show taps)
        <> "]}}},{\"turn\":1,\"step\":\"PrecombatMain\",\"player\":\"alice\",\"do\":{\"Cast\":{\"object\":\"$lox\",\"cost\":[],\"costOrder\":[0,1]}}}]}"

-- alice foretells Augury Raven on turn 1 and casts it on turn 3: when `short`,
-- from one floating {U} alone, tapping nothing during the cast.
castForetold :: Bool -> String
castForetold short =
  let islands = List.intercalate "," ["{\"card\":\"Island\",\"label\":\"i" <> show n <> "\",\"ready\":true}" | n <- [1 :: Int .. 4]]
      library = List.intercalate "," (replicate 4 "{\"card\":\"Island\"}")
      entry turn body = "{\"turn\":" <> show (turn :: Int) <> ",\"step\":\"PrecombatMain\",\"player\":\"alice\"," <> body <> "}"
      cast =
        if short
          then [entry 3 "\"do\":{\"Take\":{\"action\":\"ActivateManaAbility $i1\"}}", entry 3 "\"do\":{\"Cast\":{\"object\":\"Augury Raven\",\"mana\":[null]}}"]
          else [entry 3 "\"do\":{\"Cast\":{\"object\":\"Augury Raven\",\"mana\":[\"$i1\",\"$i2\",null]}}"]
   in "{\"description\":\"x\",\"board\":{\"seats\":[{\"name\":\"alice\",\"battlefield\":["
        <> islands
        <> "],\"hand\":[{\"card\":\"Augury Raven\",\"label\":\"raven\"}],\"library\":["
        <> library
        <> "]},{\"name\":\"bob\",\"library\":["
        <> library
        <> "]}],\"active\":\"alice\",\"step\":\"PrecombatMain\"},\"timeline\":["
        <> List.intercalate "," (entry 1 "\"do\":{\"Take\":{\"action\":\"Foretell $raven\",\"mana\":[\"$i1\",\"$i2\",null]}}" : cast)
        <> "]}"

-- alice crews Consulate Dreadnought (crew 6) by tapping `taps` from a Hill
-- Giant (power 3) and a Blind-Spot Giant (power 4).
crewDreadnought :: [String] -> String
crewDreadnought taps =
  "{\"description\":\"x\",\"board\":{\"seats\":[{\"name\":\"alice\",\"battlefield\":[{\"card\":\"Consulate Dreadnought\",\"label\":\"vehicle\",\"ready\":true},{\"card\":\"Blind-Spot Giant\",\"label\":\"blind\",\"ready\":true},{\"card\":\"Hill Giant\",\"label\":\"giant\",\"ready\":true}]},{\"name\":\"bob\"}],\"active\":\"alice\",\"step\":\"PrecombatMain\"},"
    <> "\"timeline\":[{\"turn\":1,\"step\":\"PrecombatMain\",\"player\":\"alice\",\"do\":{\"Answer\":{\"prompt\":\"ChooseTapsForTotalPower\",\"with\":["
    <> List.intercalate "," (fmap show taps)
    <> "]}}},{\"turn\":1,\"step\":\"PrecombatMain\",\"player\":\"alice\",\"do\":{\"Activate\":{\"object\":\"$vehicle\",\"ability\":0}}}]}"

-- bob casts a Goblin Piker, alice Mana Leaks it, and bob agrees to pay {3}
-- but taps nothing.
leakUnpaid :: String
leakUnpaid =
  "{\"description\":\"x\",\"board\":{\"seats\":[{\"name\":\"alice\",\"battlefield\":[{\"card\":\"Island\",\"label\":\"i1\"},{\"card\":\"Island\",\"label\":\"i2\"}],\"hand\":[{\"card\":\"Mana Leak\",\"label\":\"leak\"}]},"
    <> "{\"name\":\"bob\",\"battlefield\":[{\"card\":\"Mountain\",\"label\":\"m1\"},{\"card\":\"Mountain\",\"label\":\"m2\"},{\"card\":\"Ancient Tomb\",\"label\":\"tomb\"},{\"card\":\"Island\",\"label\":\"bi\"}],\"hand\":[{\"card\":\"Goblin Piker\",\"label\":\"piker\"}]}],\"active\":\"bob\",\"step\":\"PrecombatMain\"},"
    <> "\"timeline\":[{\"turn\":1,\"step\":\"PrecombatMain\",\"player\":\"bob\",\"do\":{\"Cast\":{\"object\":\"$piker\",\"mana\":[\"$m1\",\"$m2\",null]}}},"
    <> "{\"turn\":1,\"step\":\"PrecombatMain\",\"player\":\"alice\",\"do\":{\"Cast\":{\"object\":\"$leak\",\"targets\":[\"Goblin Piker\"],\"mana\":[\"$i1\",\"$i2\"]}}},"
    <> "{\"turn\":1,\"step\":\"PrecombatMain\",\"player\":\"alice\",\"do\":\"Pass\"},"
    <> "{\"turn\":1,\"step\":\"PrecombatMain\",\"player\":\"bob\",\"do\":{\"ChooseToPay\":{\"decision\":{\"type\":\"Pays\"},\"mana\":[null]}}}]}"

-- alice's Colossal Dreadmaw (6/6 trample), blocked by bob's War Mammoth (3/3),
-- assigns 2 to the Mammoth and 4 to bob.
trampleShort :: String
trampleShort =
  "{\"description\":\"x\",\"board\":{\"seats\":[{\"name\":\"alice\",\"battlefield\":[{\"card\":\"Colossal Dreadmaw\",\"label\":\"dreadmaw\",\"ready\":true}]},"
    <> "{\"name\":\"bob\",\"battlefield\":[{\"card\":\"War Mammoth\",\"label\":\"mammoth\",\"ready\":true}]}],\"active\":\"alice\",\"step\":\"DeclareAttackers\"},"
    <> "\"timeline\":[{\"turn\":1,\"step\":\"DeclareAttackers\",\"player\":\"alice\",\"do\":{\"Attack\":[\"$dreadmaw\"]}},"
    <> "{\"turn\":1,\"step\":\"DeclareBlockers\",\"player\":\"bob\",\"do\":{\"Block\":{\"$mammoth\":[\"$dreadmaw\"]}}},"
    <> "{\"turn\":1,\"step\":\"CombatDamage\",\"player\":\"alice\",\"source\":\"$dreadmaw\",\"do\":{\"AssignDamage\":{\"$mammoth\":2,\"$bob\":4}}}]}"

-- alice's Piker, blocked by two of bob's, assigns its damage as `assignment`.
doubleBlocked :: String -> String
doubleBlocked assignment =
  "{\"description\":\"x\",\"board\":{\"seats\":[{\"name\":\"alice\",\"battlefield\":[{\"card\":\"Goblin Piker\",\"label\":\"attacker\",\"ready\":true}]},"
    <> "{\"name\":\"bob\",\"battlefield\":[{\"card\":\"Goblin Piker\",\"label\":\"first\",\"ready\":true},{\"card\":\"Goblin Piker\",\"label\":\"second\",\"ready\":true}]}],\"active\":\"alice\",\"step\":\"DeclareAttackers\"},"
    <> "\"timeline\":[{\"turn\":1,\"step\":\"DeclareAttackers\",\"player\":\"alice\",\"do\":{\"Attack\":[\"$attacker\"]}},"
    <> "{\"turn\":1,\"step\":\"DeclareBlockers\",\"player\":\"bob\",\"do\":{\"Block\":{\"$first\":[\"$attacker\"],\"$second\":[\"$attacker\"]}}},"
    <> "{\"turn\":1,\"step\":\"CombatDamage\",\"player\":\"alice\",\"source\":\"$attacker\",\"do\":{\"AssignDamage\":"
    <> assignment
    <> "}},{\"turn\":1,\"step\":\"EndOfCombat\",\"player\":\"alice\",\"check\":{\"Life\":{\"player\":\"bob\",\"life\":20}}}]}"

-- alice's settled Piker attacks bob, then `entry` (if any) and `final`.
attackThen :: String -> String -> String
attackThen entry final =
  "{\"description\":\"x\",\"board\":{\"seats\":[{\"name\":\"alice\",\"battlefield\":[{\"card\":\"Goblin Piker\",\"label\":\"attacker\",\"ready\":true}]},{\"name\":\"bob\"}],\"active\":\"alice\",\"step\":\"DeclareAttackers\"},"
    <> "\"timeline\":[{\"turn\":1,\"step\":\"DeclareAttackers\",\"player\":\"alice\",\"do\":{\"Attack\":[\"$attacker\"]}}"
    <> (if null entry then "" else "," <> entry)
    <> "],\"final\":"
    <> final
    <> "}"

-- The same board, attacking with whatever `attacker` names.
attackThenAttacking :: String -> String
attackThenAttacking attacker =
  "{\"description\":\"x\",\"board\":{\"seats\":[{\"name\":\"alice\",\"battlefield\":[{\"card\":\"Goblin Piker\",\"label\":\"attacker\",\"ready\":true}]},{\"name\":\"bob\"}],\"active\":\"alice\",\"step\":\"DeclareAttackers\"},"
    <> "\"timeline\":[{\"turn\":1,\"step\":\"DeclareAttackers\",\"player\":\"alice\",\"do\":{\"Attack\":[\""
    <> attacker
    <> "\"]}}]}"

-- Alice answering a ChooseManaSource prompt that offers the first of two settled
-- Forests with this reference, flagged unoffered or not: the rehearsal's answer
-- and the second Forest's id.
manaSourceAnswer :: (Monad m) => Spec.Spec m n -> Registry.Registry m -> String -> Bool -> m (Either ScenarioFailure.ScenarioFailure (Maybe ObjectId.ObjectId, ObjectId.ObjectId))
manaSourceAnswer s registry named flagged = do
  let setup = S.duel S.precombatMain [S.settled "f1" "Forest", S.settled "f2" "Forest"] []
      answer = Answer.MkAnswer (Text.pack "ChooseManaSource") (Reply.Text (Text.pack named)) flagged
      script = S.turn 1 [S.on S.precombatMain S.alice (Move.Answer answer)]
  built <- S.buildBoardOrFail s registry setup
  case (Map.lookup (Label.MkLabel (Text.pack "f1")) (Staged.objects built), Map.lookup (Label.MkLabel (Text.pack "f2")) (Staged.objects built)) of
    (Just first, Just second) -> do
      let prompt = Prompt.ChooseManaSource (Decider.MkDecider S.alice) S.alice (ManaCost.MkManaCost []) (first NonEmpty.:| [])
      pure (fmap (\(chosen, _) -> (chosen, second)) (Scenario.rehearse script built (Game.ask prompt)))
    _ -> Spec.assertFailure s "the board omitted an alias"
