module Parun.Types.WhenSpent where

import qualified Parun.Types.AbilityName as AbilityName
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword

-- | CR 106.6's third shape as card data: a delayed triggered ability (CR 603.7a)
-- that triggers when the mana is spent to cast a spell -- Pyromancer's Goggles'
-- "When that mana is spent to cast a red instant or sorcery spell, copy that
-- spell". Rides Parun.Types.ManaAddition beside the restriction and the rider.
--
-- The ability by NAME, Parun.Types.ArmDelayedTrigger's reason: Parun.Types.Effect
-- is first-order, so the payload lives in Parun.Types.Face.delayedAbilities and
-- this names it. Its effects read "that spell" as Parun.Engine.Binding.castSpell.
data WhenSpent = MkWhenSpent
  { -- | Which spells spending the mana to cast fires it, matched against the spell
    -- as Parun.Types.ManaRider's condition is.
    casts :: Filter.Filter Keyword.Keyword,
    ability :: AbilityName.AbilityName
  }
  deriving (Eq, Ord, Show)
