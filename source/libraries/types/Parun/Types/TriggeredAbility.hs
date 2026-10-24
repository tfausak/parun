module Parun.Types.TriggeredAbility where

import qualified Data.Set as Set
import qualified Parun.Types.AbilityName as AbilityName
import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.Modal as Modal
import qualified Parun.Types.TriggerCondition as TriggerCondition
import qualified Parun.Types.TriggerLimit as TriggerLimit
import qualified Parun.Types.Zone as Zone

-- | CR 603.1 / 700.2b / 603.3c: "[condition], [effect]", modal-capable and
-- parametric in `card` for the reason ActivatedAbility is. On the stack it shares
-- Resolve's executor with an activated ability.
data TriggeredAbility card ability = MkTriggeredAbility
  { condition :: TriggerCondition.TriggerCondition,
    modal :: Modal.Modal card ability,
    -- | CR 603.4: an intervening "if" clause. The SAME predicate vocabulary a CR
    -- 603.8 state trigger uses, with two customers: checked when the trigger event
    -- occurs (the ability does not trigger AT ALL if it is false) and checked
    -- AGAIN on resolution (CR 608.2a removes the ability from the stack if it has
    -- become false). Nothing for every ability without one.
    intervening :: Maybe Condition.Condition,
    -- | The name another clause of the same card uses to refer to this ability,
    -- or Nothing; the same reference Parun.Types.ActivatedAbility.name is, read
    -- by CR 613.1f's Modification.LoseNamedAbility.
    name :: Maybe AbilityName.AbilityName,
    -- | Whispering Wizard's "This ability triggers only once each turn" and
    -- Acrobatic Cheerleader's "This ability triggers only once". A rider on the
    -- ABILITY rather than a narrowing of the event, which is why it sits here and
    -- not in the TriggerCondition beside it: the condition still matches every
    -- occurrence, and the rider says the ability declines all but the first.
    -- Unlimited for every ability that prints no such rider.
    --
    -- Enforced at Parun.Engine.Event.withinTriggerLimit, off the turn-scoped log
    -- for the per-turn rider and off Parun.Types.GameState.triggeredThisGame for
    -- the per-game one.
    limit :: TriggerLimit.TriggerLimit,
    -- | CR 113.6b: the zones this ability states it functions in, overriding
    -- every condition's own classification (Summitfest Closing Ceremony's
    -- covercast). Empty for an ability that states none, which leaves CR 113.6's
    -- default and CR 113.6k / 113.6m to decide; Parun.Types.StaticAbility's
    -- field of the same name is the static twin.
    functionsFrom :: Set.Set Zone.Zone
  }
  deriving (Eq, Ord, Show)
