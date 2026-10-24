module Parun.Types.InherentTriggerSource where

import qualified Parun.Types.Card as Card
import qualified Parun.Types.GrantedAbility as GrantedAbility
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.TriggeredAbility as TriggeredAbility

-- | CR 725.2 / CR 702.179d: a triggered ability with no object source,
-- controlled by a specific player baked in at trigger time (like
-- DelayedTrigger's controller). Its customers are the abilities the rulebook
-- states without a card to bear them -- the monarch's pair, and the speed
-- increase a player with 1 or more speed has.
--
-- A record rather than two positional fields, so the arm has the one payload a
-- codec needs. Parun.Types.Source is what this is an arm of.
--
-- Distinct from Parun.Types.TriggeredAbilitySource because the first field is a
-- PLAYER rather than an object: there is no object to name, which is the whole
-- of the difference.
data InherentTriggerSource = MkInherentTriggerSource
  { controller :: PlayerId.PlayerId,
    ability :: TriggeredAbility.TriggeredAbility Card.Card (GrantedAbility.GrantedAbility Card.Card)
  }
  deriving (Eq, Ord, Show)
