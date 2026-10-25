module Parun.Types.CostReduction where

import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.CostDirection as CostDirection
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.Quantity as Quantity

-- | CR 601.2f: a reduction a spell's OWN text applies to its own cost --
-- Thrasta, Tempest's Roar's "This spell costs {3} less to cast for each other
-- spell cast this turn". Its 'direction' makes it an increase instead (Dragon's
-- Prey's "costs {2} more"), the same sentence with the other sign.
--
-- A face may print that sentence out (Face.costReductions), an effect may grant
-- it (Parun.Types.GrantedAbility.SelfCostReduction, Richlau, Headmaster), or the
-- spell may have it as a rule-702 keyword, printed or granted (Mycosynth Golem),
-- which Parun.Engine.Keyword.selfCostReductionsOf mints into
-- this type: CR 702.41a's affinity and CR 702.125a's undaunted are the two, and
-- neither reaches this type through a card's own text beyond affinity's quality.
--
-- The SELF-scoped sibling of Parun.Types.CostModifier's reduction, which is a battlefield
-- permanent's static ability discounting whatever spells its Filter names
-- (Sapphire Medallion). Neither carrier can hold the other's sentence: that one
-- is a CR 613.11 continuous effect gathered off the battlefield
-- (Parun.Engine.PlayerEffect.printedRows walks it), and a spell reducing its own
-- cost is not on the battlefield when the reduction applies; this one names no
-- spells to match against, because the only spell it reduces is the one it is
-- printed on.
--
-- A printed one is read straight off the card, or its copy stamp
-- (Parun.Engine.Game.castingFaceOf), by Parun.Engine.Cost.selfReductions, which
-- drops it when a layer-6 wipe is in force on the object (CR 613.1f). A
-- granted one is read off the projection. CR 113.6d is the rule that makes
-- an ability modifying what its own object costs to cast function on the stack.
data CostReduction = MkCostReduction
  { -- | What ONE of the things counted takes off -- Thrasta's {3}.
    --
    -- A ManaCost and not a number, for Parun.Types.AppliedReduction's reason: CR
    -- 118.7 reduces a cost by mana of a stated type, and
    -- Parun.Engine.Cost.applyAdjustments already reads a reduction's generic and
    -- typed halves apart -- Ertai's Scorn's {U} is a typed one.
    amount :: ManaCost.ManaCost,
    -- | How many times 'amount' comes off -- Thrasta's "for each other spell
    -- cast this turn", which is a Count over Scope.InHistory
    -- EventShape.SpellCast.
    --
    -- A Quantity rather than a Natural, which is the whole reason this type
    -- exists: a fixed self-reduction is expressible as a Literal, and a scaling
    -- one is not expressible any other way. Evaluated at CR 601.2f, against the
    -- state as it stands there and never against an earlier snapshot -- see
    -- Parun.Engine.Cost.selfReductions. CR 601.2c's targets are announced by
    -- then, so it may count them: Fireball's "for each target beyond the
    -- first" is a BoundCount of its own slot less one.
    --
    -- Thrasta's "OTHER" needs no exclusion here and gets none: CR 601.2i is what
    -- makes a spell cast, and it comes after CR 601.2f, so the spell being
    -- totalled has filed no GameEvent.SpellCast of its own for the count to pick
    -- up.
    perEach :: Quantity.Quantity,
    -- | CR 601.2f: when the reduction applies at all; Nothing is unconditional.
    condition :: Maybe Condition.Condition,
    -- | CR 601.2c / 601.2f: the reduction applies only if the spell targets
    -- something this matches, asked of each announced object target against its
    -- own view with the spell as the source -- Bury in Books' "if it targets an
    -- attacking creature". Nothing names no target.
    --
    -- Apart from 'condition' because the gates that measure a cost before CR
    -- 601.2c (Parun.Engine.Cast.payableCostAt) have to search the aimings for a
    -- sentence reading the targets, and this field is how they know one does.
    -- Parun.Types.CostModifier's @whichTargets@ is the same question asked by
    -- another permanent's effect, of a spell or an activation.
    whichTargets :: Maybe (Filter.Filter Keyword.Keyword),
    -- | Whether 'amount' comes off the total or goes onto it -- Dragon's Prey's
    -- "costs {2} more", which joins Parun.Types.CostAdjustments.increases whole.
    direction :: CostDirection.CostDirection
  }
  deriving (Eq, Ord, Show)
