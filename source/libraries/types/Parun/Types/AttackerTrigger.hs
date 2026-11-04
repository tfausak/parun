module Parun.Types.AttackerTrigger where

import qualified Parun.Types.AttackCompany as AttackCompany
import qualified Parun.Types.AttackerTarget as AttackerTarget
import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.TriggerFrequency as TriggerFrequency

-- | CR 508.3a: "whenever [a creature] attacks", once per declared attacker. The
-- Filter names the creature (Filter.IsSource for the source's own); the
-- condition is a state that holds as it attacks (Kari Zev, Crew of Two's
-- "while you don't control a legendary Monkey"), never re-checked as
-- TriggeredAbility.intervening would be (CR 603.4).
data AttackerTrigger = MkAttackerTrigger
  { creature :: Filter.Filter Keyword.Keyword,
    target :: AttackerTarget.AttackerTarget,
    company :: AttackCompany.AttackCompany,
    frequency :: TriggerFrequency.TriggerFrequency,
    while :: Maybe Condition.Condition
  }
  deriving (Eq, Ord, Show)

-- | "Whenever this creature attacks": the source, attacking anything, with any
-- company, every time, unconditionally. The codec's defaults.
defaultValue :: AttackerTrigger
defaultValue =
  MkAttackerTrigger
    { creature = Filter.IsSource,
      target = AttackerTarget.AnyTarget,
      company = AttackCompany.AnyCompany,
      frequency = TriggerFrequency.EveryTime,
      while = Nothing
    }
