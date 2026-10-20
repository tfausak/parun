-- CR 706 past the roll itself: rule 706.6's ignored roll, and rule 706.2's
-- modifiers that reach a roll from a source other than its own instruction.
-- Rule 705's Pawl.Engine.Coin one rule over, and the same division of labour --
-- the replaceable event itself is a funnel in Pawl.Engine.Event
-- (proposeDiceRoll), because CR 614's loop lives there, and what is left of rule
-- 706 lives here.
module Pawl.Engine.Dice where

import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.List as List
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Set as Set
import qualified Numeric.Natural as Natural
import qualified Pawl.Engine.Decide as Decide
import qualified Pawl.Engine.Game as Game
import qualified Pawl.Engine.PlayerEffect as PlayerEffect
import qualified Pawl.Engine.Turn as Turn
import qualified Pawl.Extra.Integer as Integer
import Pawl.Types.Game (Game)
import Pawl.Types.GameState (GameState)
import qualified Pawl.Types.GameState as GameState
import qualified Pawl.Types.ModifiedRoll as ModifiedRoll
import Pawl.Types.ObjectId (ObjectId)
import qualified Pawl.Types.PermissionLimit as PermissionLimit
import Pawl.Types.PlayerId (PlayerId)
import qualified Pawl.Types.Prompt as Prompt
import qualified Pawl.Types.RollModifier as RollModifier

-- | The CR 706.2 modifiers in force over the rolls `pid` is making, read fresh
-- for EACH die rather than once for the instruction: rule 706.2 words a modifier
-- against "the roll" singular, and a reroll of the first die can move the board
-- the second die's offer is read off.
--
-- Pawl.Engine.Coin.statementsFor's sibling, and deliberately NOT its
-- once-per-instruction posture: that one is Edgar, King of Figaro's printed
-- "the first time you flip one or more coins each turn", plain card text with no
-- rule behind it, and no printing of a die-roll modifier says anything like it.
modifiersFor :: PlayerId -> Game [(Maybe ObjectId, ModifiedRoll.ModifiedRoll)]
modifiersFor pid = fmap (PlayerEffect.rollModifiers pid) State.get

-- | CR 706.2b's first step: which of the modifiers in force offer a REROLL of a
-- die of `sides` that came up the natural result `natural`, each still tagged
-- with the object that states it.
--
-- The NATURAL result, because rule 706.2b considers rerolls before any increase
-- or decrease -- so nothing has moved the number when this is asked, and an
-- implementation that read the instruction's own modifier in first would gate
-- Clam-I-Am's "if you roll a 3" on a number no die showed.
--
-- The matching modifiers and not a Bool, because CR 706.2a lets each one carry
-- its own COST and name its own payer, and two offers that differ in either are
-- two different questions.
--
-- An unstated `sides` or `natural` matches every roll -- Wall of Fortune's bare
-- "a die" -- rather than none.
rerollOffers :: Natural.Natural -> Natural.Natural -> [(Maybe ObjectId, ModifiedRoll.ModifiedRoll)] -> [(Maybe ObjectId, ModifiedRoll.ModifiedRoll)]
rerollOffers sides natural modifiers =
  let matches modifier =
        ModifiedRoll.modifier modifier == RollModifier.Reroll
          && all (== sides) (ModifiedRoll.sides modifier)
          && all (== natural) (ModifiedRoll.natural modifier)
   in filter (matches . snd) modifiers

-- | CR 706.2b's SECOND step: which of the modifiers in force offer to increase
-- or decrease the result of a die of `sides`, each tagged with the object that
-- states it and paired with the amount.
--
-- `natural` is not read: it is a reroll's narrowing (Clam-I-Am), and no
-- increase-or-decrease printing states one.
adjustOffers :: Natural.Natural -> [(Maybe ObjectId, ModifiedRoll.ModifiedRoll)] -> [(Maybe ObjectId, ModifiedRoll.ModifiedRoll, Natural.Natural)]
adjustOffers sides modifiers =
  let amountOf (stated, modifier) = case ModifiedRoll.modifier modifier of
        RollModifier.Reroll -> Nothing
        RollModifier.IncreaseOrDecrease amount ->
          if all (== sides) (ModifiedRoll.sides modifier) then Just (stated, modifier, amount) else Nothing
   in Maybe.mapMaybe amountOf modifiers

-- | CR 706.2b: which of the competing modifiers `roller` applies next, each
-- tagged with its payer and the object that states it, and the rest. Every
-- candidate must already be applicable now; Nothing when none is.
--
-- Asked whenever two or more stand, the roller's own included (Pawl.DiceSpec's
-- "CR 706.2b the roller picks among their own modifiers").
--
-- FILTERED, NOT TRUSTED: an index past the end takes the first.
pickModifier :: PlayerId -> [(PlayerId, Maybe ObjectId, a)] -> Game (Maybe ((PlayerId, Maybe ObjectId, a), [(PlayerId, Maybe ObjectId, a)]))
pickModifier roller candidates = case candidates of
  [] -> pure Nothing
  first : rest
    | null rest -> pure (Just (first, rest))
    | otherwise -> do
        gs <- State.get
        index <- Game.choose (Prompt.ChooseRollModifier (Decide.deciderFor roller gs) roller (fmap (\(_, stated, _) -> stated) (first NonEmpty.:| rest)))
        pure $ case List.genericSplitAt index candidates of
          (before, chosen : after) -> Just (chosen, before <> after)
          _ -> Just (first, rest)

-- | Whether a modifier's printed budget still admits it: Night Shift of the
-- Living Dead's "Do this only once each turn", read against
-- GameState.rollModifiersUsedThisTurn; a once-each-of-your-turns budget only on
-- `payer`'s own turn as well (CR 805.4a's team turn included), `payer` being
-- the modifier's "you" (CR 109.5). A
-- budgeted modifier with no object behind it has nowhere to be spent and is not
-- offered; no printing has one.
withinLimit :: GameState -> PlayerId -> Maybe ObjectId -> ModifiedRoll.ModifiedRoll -> Bool
withinLimit gs payer stated modifier =
  let unspent = case stated of
        Nothing -> False
        Just oid -> Set.notMember modifier (Map.findWithDefault Set.empty oid (GameState.rollModifiersUsedThisTurn gs))
   in case ModifiedRoll.limit modifier of
        PermissionLimit.Unlimited -> True
        PermissionLimit.OnceEachTurn -> unspent
        PermissionLimit.OnceEachOfYourTurns -> Turn.isActive gs payer && unspent

-- | Spend a modifier's budget once it is taken; a no-op for an unbudgeted one.
spendLimit :: Maybe ObjectId -> ModifiedRoll.ModifiedRoll -> GameState -> GameState
spendLimit stated modifier gs = case stated of
  Just oid
    | ModifiedRoll.limit modifier /= PermissionLimit.Unlimited ->
        gs {GameState.rollModifiersUsedThisTurn = Map.insertWith Set.union oid (Set.singleton modifier) (GameState.rollModifiersUsedThisTurn gs)}
  _ -> gs

-- | CR 706.6: throw away the `n` lowest of these rolls, so that what comes back
-- is the rolls the instruction may still read. Rule 706.6 makes an ignored roll
-- one that HAPPENED -- the die was thrown and its face asked for -- and is then
-- treated as never having happened, so this runs on the results rather than on
-- the count of dice, and the caller has already asked for every face. `value` is
-- the number a roll is compared by: a die's result, or the 1 or 20 a coin stands
-- for (Pokey, the Scallywagg).
--
-- ONE AT A TIME, re-finding the minimum after each, because CR 706.6's sentence
-- is "the lowest roll" singular and two rows each ignore their own: over [1,1,5]
-- a single ignore leaves [1,5] and a second leaves [5], where a pass that took
-- every copy of the minimum at once would leave [5] for both.
--
-- A TIE is asked about only where the board can tell the tied rolls apart.
-- Rule 706.6's second sentence gives the roller the choice "if multiple results
-- are tied for the lowest". Tied rolls are equal NUMBERS, so where nothing else
-- separates them dropping either leaves the instruction the same results, and
-- where the rules leave nothing to ask, don't prompt -- the first is taken, so a
-- transcript replays. `key` is what else a roll carries: the player who threw it
-- (Pippa, Duchess of Dice's ruling gives a reroll to its thrower's "whenever you
-- roll"), or the outcome of the call a coin standing for a die was flipped
-- against. Where the tied rolls differ in it, the roller chooses which is
-- ignored, through Prompt.ChooseDieResult, offered one roll per distinct key,
-- earliest first. FILTERED, NOT TRUSTED: an index past the end ignores the
-- first.
--
-- Ignoring more rolls than were made leaves none rather than failing; the
-- instruction then binds nothing and reads an unbound slot. Unreachable from card
-- data -- every ignore comes from a row that added the die it ignores -- and so
-- defensive.
ignoreLowest :: (Ord k) => PlayerId -> (a -> Integer) -> (a -> k) -> Natural.Natural -> [a] -> Game [a]
ignoreLowest roller valueOf keyOf n rolls = case NonEmpty.nonEmpty rolls of
  Just held | n > 0 -> do
    let low = minimum (fmap valueOf held)
        tied = [i | (i, roll) <- zip [0 :: Int ..] rolls, valueOf roll == low]
        firstOfEach seen indices = case indices of
          [] -> []
          i : rest -> case drop i rolls of
            roll : _
              | Set.member (keyOf roll) seen -> firstOfEach seen rest
              | otherwise -> i : firstOfEach (Set.insert (keyOf roll) seen) rest
            [] -> firstOfEach seen rest
    dropped <- case firstOfEach Set.empty tied of
      first : rest@(_ : _) -> do
        gs <- State.get
        answer <- Game.choose (Prompt.ChooseDieResult (Decide.deciderFor roller gs) roller Nothing (fmap (const (Integer.toNaturalSaturating low)) (first NonEmpty.:| rest)))
        pure (Maybe.fromMaybe first (Maybe.listToMaybe (List.genericDrop answer (first : rest))))
      first : _ -> pure first
      -- Unreachable: the minimum of a non-empty list is one of its members.
      [] -> pure 0
    let (before, after) = splitAt dropped rolls
    ignoreLowest roller valueOf keyOf (n - 1) (before <> drop 1 after)
  _ -> pure rolls
