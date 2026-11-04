module Parun.Types.AttackTrigger where

import qualified Parun.Types.AttackedTrigger as AttackedTrigger
import qualified Parun.Types.AttackerTrigger as AttackerTrigger
import qualified Parun.Types.DeclarationTrigger as DeclarationTrigger
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword

-- | CR 508.3: a trigger on attackers being declared, by the arity it fires at.
data AttackTrigger
  = -- | CR 508.3a: once per declared attacker.
    Attacker AttackerTrigger.AttackerTrigger
  | -- | CR 508.3b / 508.3e: once per target, or per attacking player and target.
    Attacked AttackedTrigger.AttackedTrigger
  | -- | CR 508.3c / 508.3d: once per declaration.
    Declaration DeclarationTrigger.DeclarationTrigger
  | -- | CR 508.3f / 509.1h: "attacks and isn't blocked", once per attacker the
    -- Filter admits.
    Unblocked (Filter.Filter Keyword.Keyword)
  deriving (Eq, Ord, Show)
