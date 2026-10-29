module Parun.Types.TargetSlot where

import qualified Numeric.Natural as Natural
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Pool as Pool
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SlotCount as SlotCount
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.SlotPerPlayer as SlotPerPlayer
import qualified Parun.Types.TargetCount as TargetCount
import qualified Parun.Types.Together as Together

-- | What a target slot may hold: a closed Pool of candidate recipients (CR 115),
-- narrowed by an open Filter (Nothing = the whole pool, e.g. bare "target
-- creature"). This retires the whole hand-carved family of colour- and
-- type-restricted target constructors (#40): each is now one data value.
--
-- CR 601.2c's "another" is not a third field: it is a Filter.Not inside the
-- Filter, which is what makes the exclusion agree with the Pool's own recipient
-- tagging. A separate field was applied by deleting a Recipient.ToObject, which
-- never matched the ToCreature tags a Creatures pool produces, so "another
-- target creature" did not exclude itself.
--
-- WHAT it excludes is what the printed word points at, and the two readings are
-- different atoms: Filter.IsSource for the ability's own source (Flensing
-- Raptor's "another target creature you control"), and Filter.IsBound for a
-- SIBLING slot of the same announcement (Fall of the Hammer's second slot,
-- "another target creature"). Rule 601.2c makes
-- sharing between two instances of "target" the default, so the second is a
-- restriction the card writes rather than one the machinery imposes;
-- Parun.Engine.Target.jointlyJudged is where an announcement carrying one is
-- judged whole.
--
-- HOW MANY the slot takes is the `count` field (CR 601.2c), which covers CR
-- 115.6's "up to one", every larger count, "any number of target ..." -- that
-- one by naming no maximum -- CR 601.2b's announced X, exactly or up to it, and
-- up to a number the board computes. On the slot and not on the mode, because a card makes the call per slot
-- -- Explosive Entry's artifact and creature slots are separately optional.
--
-- `filter` shadows the Prelude's, for the reason Parun.Types.Count's does.
data TargetSlot = MkTargetSlot
  { pool :: Pool.Pool,
    filter :: Maybe (Filter.Filter Keyword.Keyword),
    count :: SlotCount.SlotCount,
    -- | CR 202.3 / 601.2c: the COMPUTED number this slot's Filter compares a
    -- candidate's mana value against -- Celestine, the Living Saint's "creature
    -- card with mana value X or less ... where X is the amount of life you gained
    -- this turn". Filter.Measures' EnclosingAmount operand is what reads it --
    -- at equality too, Chthonian Nightmare's "with mana value X" -- and against a
    -- candidate's POWER as well (Spawnbroker).
    -- Parun.Engine.Target.slotContext is where it is evaluated and handed over.
    --
    -- HERE rather than in the Filter arm, which is where it belongs on the face of
    -- it: Parun.Types.Quantity imports Parun.Types.Count, which imports this
    -- module's Filter, so an arm carrying a Quantity closes a module cycle. The
    -- repo's way out of such a cycle is parametric polymorphism -- Filter is
    -- already parametric in its keyword for exactly that reason -- but a second
    -- parameter does not reach here: Parun.Types.Keyword itself holds a
    -- `Filter.Filter Keyword` (Protection, Landwalk, Hexproof) and imports no
    -- Quantity, so a quantity parameter on Filter would make Keyword hold one,
    -- and Quantity imports Keyword. Breaking THAT cycle means a quantity
    -- parameter on Keyword too, and on KeywordFamily behind it. A field on the
    -- slot costs one record field and reaches every bound the pool prints.
    --
    -- ON THE SLOT rather than one nullary operand per printed bound (an
    -- OfSource-shaped life-gained tally), because Betor,
    -- Ancestor's Voice prints the bound against life LOST this turn beside the
    -- gained one: the operand-per-bound shape owes a new operand, a new
    -- Parun.Engine.Filter.Context field and a new position lint for each, where a
    -- slot naming its own Quantity owes nothing.
    --
    -- Nothing on every slot but the ones that print such a bound, which is all but
    -- a handful: the operand is vacuously False against a Nothing here, and
    -- Parun.CardSpec's position lint is what keeps a card from writing one into a
    -- slot that names no amount.
    --
    -- A bound that reads a SLOT is answered off the ANNOUNCEMENT rather than off
    -- CR 113.7's source, which carries no such binding: Parun.Engine.Target's
    -- slotContext hands the environment to Parun.Engine.Quantity through
    -- Filter.Context's boundAmounts. Both announcements reach it -- CR 603.2's
    -- trigger event (Venerable Warsinger's "where X is the amount of damage this
    -- creature dealt to that player", proved by Parun.TargetSpec's "CR 603.2 whole
    -- card: the bound is the damage the event carried") and CR 601.2b's announced
    -- X on a spell (Stir the Grave's "mana value X or less", proved by that
    -- module's "CR 601.2c whole card: the bound is the X the caster announced").
    amount :: Maybe Quantity.Quantity,
    -- | CR 115.1 / 601.2c: WHO announces this slot's targets -- Cuombajj
    -- Witches' "1 damage to any target of an opponent's choice", Curse of
    -- Inertia's "that attacking player may tap or untap target permanent of
    -- their choice". Nothing is the rule's default, the controller, which is
    -- every other slot in the corpus.
    --
    -- Never a seat by id: CR 601.2c's announcement precedes every binding the
    -- announcement itself makes, so a slot names its chooser by relation to the
    -- controller or through a binding the announcement already holds -- CR
    -- 603.2's trigger-event bindings, there before CR 603.3d's announcement.
    -- Resolving it to a seat is Parun.Engine.Target.chooserOf's.
    --
    -- ON THE SLOT rather than on the ability, because Cuombajj Witches prints
    -- both readings in one activation: its first target is the controller's and
    -- its second an opponent's.
    --
    -- Whose choice it is does NOT move CR 109.5's "you". Legality is still judged
    -- from the ability's controller -- hexproof asks who controls the ability (CR
    -- 702.11b), not who points it -- so only the prompt's seat changes.
    chooser :: Maybe PlayerRef.PlayerRef,
    -- | CR 601.2c: "for each opponent, ... target ... that player controls" --
    -- the slot announced once per player, each copy with its own "that player"
    -- (Parun.Engine.Target.announcedSlots). Nothing is one ordinary slot.
    perPlayer :: Maybe SlotPerPlayer.SlotPerPlayer,
    -- | CR 601.2d: the total the caster divides among this slot's targets as
    -- the spell is cast, each target getting at least one (Forked Lightning's
    -- "4 damage divided as you choose"); Quantity.Share reads a target's part.
    -- Nothing is an undivided slot.
    divided :: Maybe Quantity.Quantity,
    -- | CR 601.2c: what this slot's targets must share, judged over the whole
    -- answer (Parun.Engine.Target.togetherRefused). Nothing relates no two of
    -- them.
    together :: Maybe Together.Together
  }
  deriving (Eq, Ord, Show)

-- The ordinary "target creature" slot: exactly one recipient. Named because
-- almost every slot in the engine and the corpus is one, so writing the count out
-- at each would bury the handful that are not.
required :: Pool.Pool -> Maybe (Filter.Filter Keyword.Keyword) -> TargetSlot
required p f = MkTargetSlot p f (SlotCount.Printed TargetCount.one) Nothing Nothing Nothing Nothing Nothing

-- CR 115.6 / 601.2c's "up to N targets": a slot the caster may fill any number of
-- times up to N, the empty answer included.
upTo :: Natural.Natural -> Pool.Pool -> Maybe (Filter.Filter Keyword.Keyword) -> TargetSlot
upTo n p f = MkTargetSlot p f (SlotCount.Printed (TargetCount.upTo n)) Nothing Nothing Nothing Nothing Nothing

-- CR 601.2c's "any number of target ...": the same slot with no printed ceiling,
-- so the board's candidates are the only bound.
anyNumber :: Pool.Pool -> Maybe (Filter.Filter Keyword.Keyword) -> TargetSlot
anyNumber p f = MkTargetSlot p f (SlotCount.Printed TargetCount.anyNumber) Nothing Nothing Nothing Nothing Nothing

-- CR 601.2c with CR 601.2b: a slot taking exactly the X the caster announced
-- ("each of X target creatures", Rot-Curse Rakshasa).
announcedX :: Pool.Pool -> Maybe (Filter.Filter Keyword.Keyword) -> TargetSlot
announcedX p f = MkTargetSlot p f SlotCount.AnnouncedX Nothing Nothing Nothing Nothing Nothing

-- CR 601.2c: the same slot with the computed bound its Filter compares against --
-- see `amount` above. Separate from the three builders so that the slots that
-- name no amount, which is almost every slot, stay spelled as they were.
withAmount :: Quantity.Quantity -> TargetSlot -> TargetSlot
withAmount q slot = slot {amount = Just q}

-- CR 115.1's default overridden: the same slot announced by somebody other than
-- the ability's controller. Separate from the four builders above so that the
-- slots the controller chooses, which is almost every slot, stay spelled as they
-- were.
chosenBy :: PlayerRef.PlayerRef -> TargetSlot -> TargetSlot
chosenBy who slot = slot {chooser = Just who}

-- CR 601.2c's "for each opponent": the same slot announced once per player the
-- relation names, `thatPlayer` naming that player for the slot's own Filter and pool.
forEachPlayer :: PlayerRelation.PlayerRelation -> SlotName.SlotName -> TargetSlot -> TargetSlot
forEachPlayer relation thatPlayer slot = slot {perPlayer = Just (SlotPerPlayer.MkSlotPerPlayer relation thatPlayer)}
