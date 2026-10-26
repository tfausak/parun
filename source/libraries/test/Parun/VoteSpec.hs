{-# LANGUAGE GADTs #-}
{-# LANGUAGE RankNTypes #-}

-- CR 701.38's vote: Parun.Engine.Resolve.Arms.Zones's Effect.Vote arm, the
-- Parun.Types.Vote payload it reads, Prompt.ChooseVote over each kind of listed
-- choice, Quantity.VotesReceived, Parun.Engine.PlayerEffect's
-- votesAllowed, and Parun.Engine.Game's turnOrderFrom,
-- which rule 701.38a's "starting with a specified player and proceeding in turn
-- order" is the second reader of (CR 101.4 is the first).
--
-- The object vote's producer is Council's Judgment {1}{W}{W} Sorcery: "Will of
-- the council -- Starting with you, each player votes for a nonland permanent
-- you don't control. Exile each permanent with the most votes or tied for most
-- votes."
--
-- The word vote's is Plea for Power {3}{U} Sorcery: "Will of the council --
-- Starting with you, each player votes for time or knowledge. If time gets more
-- votes, take an extra turn after this one. If knowledge gets more votes or the
-- vote is tied, draw three cards." Rule 701.38d's extra vote is Brago's
-- Representative {2}{W} Creature -- Human Advisor: "While voting, you get an
-- additional vote." Its optional twin is Ballot Broker {2}{W} Creature -- Human
-- Advisor: "While voting, you may vote an additional time."
--
-- The player vote's is Mob Verdict {2}{R}{R} Sorcery: "Secret council -- Each
-- player secretly votes for another player, then those votes are revealed. ..."
--
-- THREE SEATS, because on two a tally cannot have a strict winner and a strict
-- loser at once, and the exile could follow the candidate list rather than the
-- count without the board telling the difference. Three seats also make three
-- ballots, which cannot TIE over two words -- so the tie half of Plea for
-- Power's second sentence is reachable only with a fourth ballot, Brago's
-- Representative's or Ballot Broker's, which is why they sit in one group.
module Parun.VoteSpec where

import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.Foldable as Foldable
import qualified Data.List as List
import qualified Data.Map.Strict as Map
import qualified Data.Text as Text
import Numeric.Natural (Natural)
import qualified Parun.Engine.Engine as Engine
import qualified Parun.Engine.Game as Game
import qualified Parun.Engine.Quantity as Quantity
import qualified Parun.Engine.Resolve.Effect as Resolve
import qualified Parun.Engine.Resolve.Slots as Slots
import qualified Parun.Engine.Stack as Stack
import qualified Parun.Registry as Registry
import qualified Parun.Spec as Spec
import qualified Parun.Support as S
import qualified Parun.Types.BallotChoice as BallotChoice
import qualified Parun.Types.Binding as Binding
import qualified Parun.Types.CardName as CardName
import qualified Parun.Types.Effect as Effect
import qualified Parun.Types.ExtraTurn as ExtraTurn
import qualified Parun.Types.GameState as GameState
import qualified Parun.Types.Object as Object
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.OptionalDecision as OptionalDecision
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Prompt as Prompt
import qualified Parun.Types.Quantity as Quantity.Type
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.Vote as Vote
import qualified Parun.Types.VoteChoices as VoteChoices
import qualified Parun.Types.VotePlayers as VotePlayers
import qualified Parun.Types.VotesReceived as VotesReceived
import qualified Parun.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
spec s registry = Spec.describe s "Parun.Engine.Vote" $ do
  councilsJudgmentSpec s registry
  pleaForPowerSpec s registry
  playerVoteSpec s registry

-- Alice's Wall of Stone, a Mountain and a Goblin Piker under bob, Typhoid Rats
-- under carol, three Plains for alice to cast with, and Council's Judgment in her
-- hand. Returns the Wall, the Mountain, the Piker, the Rats, the spell and that
-- state.
--
-- The four permanents are placed first, so ObjectId order runs Wall, Mountain,
-- Piker, Rats -- and that is the order
-- Parun.Engine.Resolve.Slots.battlefieldMatching offers the choices in, the lands
-- behind them matching nothing.
judgmentBoard ::
  (Monad m) =>
  Spec.Spec m n ->
  Registry.Registry m ->
  m (ObjectId.ObjectId, ObjectId.ObjectId, ObjectId.ObjectId, ObjectId.ObjectId, ObjectId.ObjectId, GameState.GameState)
judgmentBoard s registry = do
  wall <- S.printingOf s registry "Wall of Stone"
  mountain <- S.printingOf s registry "Mountain"
  piker <- S.printingOf s registry "Goblin Piker"
  rats <- S.printingOf s registry "Typhoid Rats"
  plains <- S.printingOf s registry "Plains"
  judgment <- S.printingOf s registry "Council's Judgment"
  let (aWall, g1) = S.addPermanent wall S.alice S.threePlayerGame
      (bMountain, g2) = S.addPermanent mountain S.bob g1
      (bPiker, g3) = S.addPermanent piker S.bob g2
      (cRats, g4) = S.addPermanent rats S.carol g3
      (g5, spell) = S.handOne judgment (S.landsFor plains S.alice 3 g4)
  pure (aWall, bMountain, bPiker, cRats, spell, g5)

-- The card names in one player's copy of a zone. CR 400.7 mints a fresh
-- incarnation at the destination, so the exiled permanent is read by NAME rather
-- than by the ObjectId it had on the battlefield.
namesIn :: Zone.Zone -> PlayerId.PlayerId -> GameState.GameState -> [Maybe CardName.CardName]
namesIn zone pid gs = fmap (\oid -> fmap S.nameOf (Game.cardOf oid gs)) (Game.zoneMembers zone pid gs)

-- Answers Prompt.ChooseVote with the choice pinned for the SEAT the prompt names
-- and records, in the order they were asked, which seat was asked and what it was
-- offered. Everything else defers to S.identityAnswer.
--
-- Keyed by seat, and stateful rather than pure, because every ballot in one vote
-- is a structurally identical prompt: a pure answerer would give all three seats
-- the same answer and the tally could not discriminate.
votingFor ::
  [(PlayerId.PlayerId, ObjectId.ObjectId)] ->
  Prompt.Prompt r ->
  State.State [(PlayerId.PlayerId, [ObjectId.ObjectId])] r
votingFor pins p = case p of
  Prompt.ChooseVote _ pid _ offered -> do
    State.modify (<> [(pid, foldMap Foldable.toList offered)])
    pure $ case lookup pid pins of
      Just oid -> BallotChoice.ForObject oid
      Nothing -> S.identityAnswer p
  _ -> pure (S.identityAnswer p)

councilsJudgmentSpec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
councilsJudgmentSpec s registry = Spec.describe s "Council's Judgment" $ do
  -- Two seats name bob's Piker and one names carol's Rats, so one resolution has
  -- a strict winner and a strict loser: the exile that takes the Piker has to
  -- leave the Rats alone, which is what says it followed the count rather than
  -- the candidate list.
  Spec.it s "CR 701.38a the permanent with the most votes is exiled and the rest are not" $ do
    piker <- S.printingOf s registry "Goblin Piker"
    (aWall, bMountain, bPiker, cRats, spell, gs) <- judgmentBoard s registry
    let pins = [(S.alice, bPiker), (S.bob, cRats), (S.carol, bPiker)]
        ((_, after), asked) = State.runState (Engine.runGame (votingFor pins) gs (S.cast S.alice spell >> Stack.resolveTop)) []
    Spec.assertEqWith s "bob's Piker, whom alice and carol both voted for, is the one card in exile" (namesIn Zone.Exile S.bob after) [Just (S.printingName piker)]
    Spec.assertBool s (S.onBattlefield cRats after) "carol's Rats, with the one vote bob cast, is still on the battlefield"
    -- Rule 701.38a's ORDER and rule 701.38b's list of choices in one read: alice
    -- is the "specified player" the printed sentence names, the other two follow
    -- her in turn order, and all three are offered the same two permanents --
    -- alice's own Wall failing "you don't control", bob's Mountain failing
    -- "nonland", and neither leaving the battlefield.
    Spec.assertEqWith
      s
      "each seat votes once, starting with alice and proceeding in turn order, between the two nonland permanents alice does not control"
      asked
      [(S.alice, [bPiker, cRats]), (S.bob, [bPiker, cRats]), (S.carol, [bPiker, cRats])]
    Spec.assertBool s (S.onBattlefield aWall after && S.onBattlefield bMountain after) "neither permanent the filter excludes left the battlefield"
  -- The same board with the votes the other way round, so the winner is the
  -- LAST of the offered pair: a vote that took the offered set's front would
  -- exile the Piker again.
  Spec.it s "CR 701.38a the same board voted the other way exiles the other permanent" $ do
    rats <- S.printingOf s registry "Typhoid Rats"
    (_, _, bPiker, cRats, spell, gs) <- judgmentBoard s registry
    let pins = [(S.alice, cRats), (S.bob, bPiker), (S.carol, cRats)]
        ((_, after), _) = State.runState (Engine.runGame (votingFor pins) gs (S.cast S.alice spell >> Stack.resolveTop)) []
    Spec.assertEqWith s "carol's Rats, whom alice and carol both voted for, is the one card in exile" (namesIn Zone.Exile S.carol after) [Just (S.printingName rats)]
    Spec.assertBool s (S.onBattlefield bPiker after) "bob's Piker, with the one vote bob cast, is still on the battlefield"

-- Alice's four Islands, Plea for Power in her hand, and three Mountains in her
-- library so the printed "draw three cards" has cards to draw (CR 104.3c).
-- `representatives` many copies of the named vote-granting creature (Brago's
-- Representative, Ballot Broker) under her control. Returns the spell and that
-- state.
pleaBoard ::
  (Monad m) =>
  Spec.Spec m n ->
  Registry.Registry m ->
  String ->
  Int ->
  m (ObjectId.ObjectId, GameState.GameState)
pleaBoard s registry granter representatives = do
  island <- S.printingOf s registry "Island"
  mountain <- S.printingOf s registry "Mountain"
  plea <- S.printingOf s registry "Plea for Power"
  representative <- S.printingOf s registry granter
  let g1 = S.landsFor island S.alice 4 S.threePlayerGame
      g2 = List.foldl' (\gs _ -> snd (S.addPermanent representative S.alice gs)) g1 [1 .. representatives]
      g3 = List.foldl' (\gs _ -> snd (S.addLibraryCard mountain S.alice gs)) g2 [1 .. 3 :: Int]
      (g4, spell) = S.handOne plea g3
  pure (spell, g4)

-- Answers a word vote's Prompt.ChooseVote from a list of ballots consumed in the order the
-- prompts are raised, and records which seat each prompt named and what it was
-- offered. Everything else defers to S.identityAnswer.
--
-- Consumed BY POSITION rather than keyed by seat, which is what lets one seat's
-- two ballots (CR 701.38d) go to different words -- a seat-keyed answerer would
-- give them both the same answer and the tie could not be built.
votingWords ::
  Prompt.Prompt r ->
  State.State ([SlotName.SlotName], [(PlayerId.PlayerId, [SlotName.SlotName])]) r
votingWords p = case p of
  Prompt.ChooseVote _ pid _ offered -> do
    (pending, asked) <- State.get
    State.put (drop 1 pending, asked <> [(pid, foldMap wordOf offered)])
    pure (case pending of chosen : _ -> BallotChoice.ForWord chosen; [] -> S.identityAnswer p)
  _ -> pure (S.identityAnswer p)

word :: String -> SlotName.SlotName
word = SlotName.MkSlotName . Text.pack

-- The word a listed choice names, if it names one.
wordOf :: BallotChoice.BallotChoice o -> [SlotName.SlotName]
wordOf choice = case choice of
  BallotChoice.ForWord w -> [w]
  _ -> []

-- The player a listed choice names, if it names one.
playerOf :: BallotChoice.BallotChoice o -> [PlayerId.PlayerId]
playerOf choice = case choice of
  BallotChoice.ForPlayer pid -> [pid]
  _ -> []

-- How many cards are in alice's hand, and whom the extra turns queued are for:
-- the two observable halves of Plea for Power's two gated clauses.
outcome :: GameState.GameState -> (Int, [PlayerId.PlayerId])
outcome gs = (length (Game.zoneMembers Zone.Hand S.alice gs), fmap ExtraTurn.taker (GameState.extraTurns gs))

pleaForPowerSpec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
pleaForPowerSpec s registry = Spec.describe s "Plea for Power" $ do
  -- Two knowledge ballots against one time ballot, so the printed "if knowledge
  -- gets more votes" holds and "if time gets more votes" does not. The draw is
  -- what says a clause read the WORD's tally: nothing else on this board tells
  -- the two sentences apart.
  Spec.it s "CR 701.38b a clause gated on a word's tally happens and the clause gated on the other does not" $ do
    (spell, gs) <- pleaBoard s registry "Brago's Representative" 0
    let ballots = [word "time", word "knowledge", word "knowledge"]
        ((_, after), (_, asked)) = State.runState (Engine.runGame votingWords gs (S.cast S.alice spell >> Stack.resolveTop)) (ballots, [])
    Spec.assertEqWith s "knowledge won, so alice drew three cards and took no extra turn" (outcome after) (3, [])
    -- Rule 701.38a's order and rule 701.38b's list in one read: alice is the
    -- "specified player", the other two follow her in turn order, and all three
    -- are offered the same two words in printed order.
    Spec.assertEqWith
      s
      "each seat votes once, starting with alice and proceeding in turn order, between the two printed words"
      asked
      [(S.alice, [word "time", word "knowledge"]), (S.bob, [word "time", word "knowledge"]), (S.carol, [word "time", word "knowledge"])]
  -- CR 701.38d's extra vote makes FOUR ballots, which is the only way two words
  -- tie at this table. Alice's two go to different words, which Brago's
  -- Representative's reminder text allows, so the tally is two all and the "or
  -- the vote is tied" is what admits the draw.
  Spec.it s "CR 701.38d an additional vote is a second ballot for that seat, taken before the next seat votes" $ do
    (spell, gs) <- pleaBoard s registry "Brago's Representative" 1
    let ballots = [word "time", word "knowledge", word "time", word "knowledge"]
        ((_, after), (_, asked)) = State.runState (Engine.runGame votingWords gs (S.cast S.alice spell >> Stack.resolveTop)) (ballots, [])
    Spec.assertEqWith s "the vote is two all, so alice drew three cards and took no extra turn" (outcome after) (3, [])
    Spec.assertEqWith
      s
      "alice is asked twice in a row and the other two seats once each"
      (fmap fst asked)
      [S.alice, S.alice, S.bob, S.carol]
  -- Ballot Broker's "you may vote an additional time" (CR 701.38d), one board
  -- answered both ways. The same four ballots in the same order: taken up,
  -- alice's two split the words and the tie draws; declined, carol's vote is the
  -- second for time and the extra turn is taken instead.
  Spec.it s "CR 701.38d a vote a player may cast is cast when they take it up, before the next seat votes" $ do
    (spell, gs) <- pleaBoard s registry "Ballot Broker" 1
    let ballots = [word "time", word "knowledge", word "time", word "knowledge"]
        ((_, after), (_, asked)) = State.runState (Engine.runGame (mayVotingWords OptionalDecision.Exercises) gs (S.cast S.alice spell >> Stack.resolveTop)) (ballots, [])
    Spec.assertEqWith s "the vote is two all, so alice drew three cards and took no extra turn" (outcome after) (3, [])
    Spec.assertEqWith
      s
      "alice is asked her own ballot, then the may, then her extra ballot, all before bob and carol"
      asked
      [Right S.alice, Left S.alice, Right S.alice, Right S.bob, Right S.carol]
  Spec.it s "CR 701.38d a vote a player may cast is not cast when they decline it" $ do
    (spell, gs) <- pleaBoard s registry "Ballot Broker" 1
    let ballots = [word "time", word "knowledge", word "time", word "knowledge"]
        ((_, after), (_, asked)) = State.runState (Engine.runGame (mayVotingWords OptionalDecision.Declines) gs (S.cast S.alice spell >> Stack.resolveTop)) (ballots, [])
    Spec.assertEqWith s "time won two to one, so alice took an extra turn and drew nothing" (outcome after) (0, [S.alice])
    Spec.assertEqWith s "alice is still asked the may" asked [Right S.alice, Left S.alice, Right S.bob, Right S.carol]

-- votingWords that answers every Prompt.OfferedExtra with `decision`. Records
-- each ballot's seat as Right and each "may" as Left, in the order asked.
mayVotingWords ::
  OptionalDecision.OptionalDecision ->
  Prompt.Prompt r ->
  State.State ([SlotName.SlotName], [Either PlayerId.PlayerId PlayerId.PlayerId]) r
mayVotingWords decision p = case p of
  Prompt.ChooseVote _ pid _ _ -> do
    (pending, asked) <- State.get
    State.put (drop 1 pending, asked <> [Right pid])
    pure (case pending of chosen : _ -> BallotChoice.ForWord chosen; [] -> S.identityAnswer p)
  Prompt.OfferedExtra _ pid _ _ -> do
    State.modify (fmap (<> [Left pid]))
    pure decision
  _ -> pure (S.identityAnswer p)

-- Answers a player vote's Prompt.ChooseVote from a list of picks consumed in the order the
-- prompts are raised, and records which seat each prompt named and what it was
-- offered. Everything else defers to S.identityAnswer. Positional for
-- votingWords' reason: CR 701.38d's second ballot is its own answer.
votingPlayers ::
  Prompt.Prompt r ->
  State.State ([PlayerId.PlayerId], [(PlayerId.PlayerId, [PlayerId.PlayerId])]) r
votingPlayers p = case p of
  Prompt.ChooseVote _ pid _ offered -> do
    (pending, asked) <- State.get
    State.put (drop 1 pending, asked <> [(pid, foldMap playerOf offered)])
    pure (case pending of chosen : _ -> BallotChoice.ForPlayer chosen; [] -> S.identityAnswer p)
  _ -> pure (S.identityAnswer p)

-- The slot Mob Verdict's tally is bound at.
votesSlot :: SlotName.SlotName
votesSlot = word "votes"

-- Mob Verdict's "each player votes for another player", starting with alice,
-- resolved by `resolving` for `source` under alice with `picks` as the ballots
-- in voting order. Returns the seats asked with what each was offered, and the
-- state after.
playerVote ::
  ObjectId.ObjectId ->
  ObjectId.ObjectId ->
  [PlayerId.PlayerId] ->
  GameState.GameState ->
  ([(PlayerId.PlayerId, [PlayerId.PlayerId])], GameState.GameState)
playerVote resolving source picks gs =
  let vote = Effect.Vote (Vote.MkVote (PlayerRef.Relative PlayerRelation.You) (VoteChoices.Players (VotePlayers.MkVotePlayers True votesSlot)) False)
      ((_, after), (_, asked)) = State.runState (Engine.runGame votingPlayers gs (Resolve.applyEffect resolving source S.alice Map.empty Map.empty vote)) (picks, [])
   in (asked, after)

-- The tally map bound at the vote's slot on `holder`.
boundTally :: ObjectId.ObjectId -> GameState.GameState -> Maybe (Map.Map PlayerId.PlayerId Natural)
boundTally holder gs = Game.lookupObject holder gs >>= Map.lookup votesSlot . Object.bindings >>= Binding.votes

-- Quantity.VotesReceived for one seat, read through the resolution's own
-- evaluation context as a later clause of the same resolution reads it.
received :: ObjectId.ObjectId -> ObjectId.ObjectId -> GameState.GameState -> PlayerId.PlayerId -> Maybe Integer
received resolving source gs pid =
  Quantity.evaluate
    (Slots.effectViewOf source Map.empty gs)
    (Slots.effectContext gs resolving S.alice source Map.empty (Slots.slotBindings resolving gs))
    gs
    source
    (Quantity.Type.VotesReceived (VotesReceived.MkVotesReceived votesSlot (PlayerRef.Specific pid)))

-- CR 701.38b's third kind, a vote for a player (Mob Verdict). A Wall of Stone
-- under alice stands in as the source.
playerVoteSpec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
playerVoteSpec s registry = Spec.describe s "player vote" $ do
  Spec.it s "a player vote binds each candidate's tally, zeros included" $ do
    wall <- S.printingOf s registry "Wall of Stone"
    let (source, gs) = S.addPermanent wall S.alice S.threePlayerGame
        (_, after) = playerVote source source [S.carol, S.carol, S.alice] gs
    Spec.assertEqWith s "the bound tally keys every seat, bob's zero included" (boundTally source after) (Just (Map.fromList [(S.alice, 1), (S.bob, 0), (S.carol, 2)]))
    Spec.assertEqWith s "VotesReceived reads each seat's tally" (fmap (received source source after) [S.alice, S.bob, S.carol]) [Just 1, Just 0, Just 2]
  Spec.it s "another player: a voter is never offered themself" $ do
    wall <- S.printingOf s registry "Wall of Stone"
    let (source, gs) = S.addPermanent wall S.alice S.threePlayerGame
        (asked, _) = playerVote source source [S.carol, S.carol, S.alice] gs
    Spec.assertEqWith
      s
      "each seat, from alice in turn order, is offered the other two seats"
      asked
      [(S.alice, [S.bob, S.carol]), (S.bob, [S.alice, S.carol]), (S.carol, [S.alice, S.bob])]
  Spec.it s "an extra vote counts toward the tally (CR 701.38d)" $ do
    wall <- S.printingOf s registry "Wall of Stone"
    representative <- S.printingOf s registry "Brago's Representative"
    let (source, g1) = S.addPermanent wall S.alice S.threePlayerGame
        (_, gs) = S.addPermanent representative S.alice g1
        (asked, after) = playerVote source source [S.bob, S.carol, S.carol, S.alice] gs
    Spec.assertEqWith s "alice is asked twice in a row and the other two seats once each" (fmap fst asked) [S.alice, S.alice, S.bob, S.carol]
    Spec.assertEqWith s "alice's second ballot counts: carol has two votes and bob one" (boundTally source after) (Just (Map.fromList [(S.alice, 1), (S.bob, 1), (S.carol, 2)]))
  -- A stack object resolving the vote for a permanent source, as a triggered
  -- ability's vote would: the tally lands on the resolving object, where
  -- effectContext's slotBindings reads it, and not on the source.
  Spec.it s "the tally is bound and read on the resolving object, not the source" $ do
    wall <- S.printingOf s registry "Wall of Stone"
    verdict <- S.printingOf s registry "Mob Verdict"
    let (source, g1) = S.addPermanent wall S.alice S.threePlayerGame
        (resolving, gs) = S.spellOnStack verdict S.alice g1
        (_, after) = playerVote resolving source [S.carol, S.carol, S.alice] gs
    Spec.assertEqWith s "VotesReceived, read through the resolving object, answers each seat's tally" (fmap (received resolving source after) [S.alice, S.bob, S.carol]) [Just 1, Just 0, Just 2]
    Spec.assertEqWith s "the resolving object holds the tally" (boundTally resolving after) (Just (Map.fromList [(S.alice, 1), (S.bob, 0), (S.carol, 2)]))
    Spec.assertEqWith s "and the source holds none" (boundTally source after) Nothing
