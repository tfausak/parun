module Parun.Types.AlternativeActivationCost where

import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.KeywordDesignator as KeywordDesignator
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.TurnScope as TurnScope

-- | The payload of Parun.Types.PlayerEffect's AlternativeActivationCost arm:
-- Kíli the Resourceful's "you may pay {0} rather than pay the equip cost of the
-- first equip ability you activate each turn". CR 118.9 through CR 602.2b: the
-- player may announce this cost at CR 601.2b in place of the ability's whole
-- activation cost, and CR 118.9d then applies increases and reductions to it.
data AlternativeActivationCost = MkAlternativeActivationCost
  { -- | The rule 702 keyword whose ability it replaces the cost of -- "the
    -- EQUIP cost", compared through Parun.Types.ActivatedAbility.keyword.
    grantedBy :: KeywordDesignator.KeywordDesignator Keyword.Keyword,
    -- | "Of the FIRST equip ability you activate each turn", read exactly as
    -- Parun.Types.CostModifier.onlyFirst is. Nothing is every matching
    -- activation.
    onlyFirst :: Maybe TurnScope.TurnScope,
    -- | What is paid instead: the {0}.
    cost :: ManaCost.ManaCost
  }
  deriving (Eq, Ord, Show)
