module Parun.Types.TappedForManaTrigger where

import qualified Parun.Types.ManaSpecification as ManaSpecification
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.TappedPermanent as TappedPermanent

-- | CR 106.12a: which permanent being tapped for mana fires the ability, by
-- whose tap, and for which mana -- Wild Growth's "whenever enchanted land is
-- tapped for mana", Autumn Willow, Harmony's "whenever you tap a land creature
-- for mana".
--
-- A record for Parun.Types.PlayerActsOn's reason: the printed form pairs a
-- subject with its narrowings, and no field has a default -- Mirari's Wake's
-- "whenever you tap a land for mana" spells the subject out as a Land filter
-- rather than leaving it absent, and its silence about the mana out as
-- ManaSpecification.AnyMana.
data TappedForManaTrigger = MkTappedForManaTrigger
  { permanent :: TappedPermanent.TappedPermanent,
    -- | The tapping player, the mana ability's controller (CR 113.8), read
    -- against CR 109.5's "you".
    player :: PlayerRelation.PlayerRelation,
    -- | CR 106.12a's second half, "or is tapped for mana of a specified type" --
    -- Gauntlet of Power's "for mana of the chosen color". No default here
    -- either: a wording that narrows the mana not at all spells itself out as
    -- ManaSpecification.AnyMana, as one that narrows the player not at all
    -- spells itself out as PlayerRelation.AnyPlayer.
    mana :: ManaSpecification.ManaSpecification
  }
  deriving (Eq, Ord, Show)
