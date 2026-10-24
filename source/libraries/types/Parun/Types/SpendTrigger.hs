module Parun.Types.SpendTrigger where

import qualified Parun.Types.Card as Card
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.GrantedAbility as GrantedAbility
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.TriggeredAbility as TriggeredAbility

-- | CR 603.7a: the delayed triggered ability a Parun.Types.WhenSpent created as its
-- mana was produced, carried on each unit (Parun.Types.ManaUnit) until the unit
-- is spent. CR 106.6a: one per mana produced.
--
-- The ability's text, source and controller are fixed at creation (CR 603.7c,
-- 603.7e), so they are stamped here rather than looked up at the spend, when the
-- source may be gone.
data SpendTrigger = MkSpendTrigger
  { casts :: Filter.Filter Keyword.Keyword,
    ability :: TriggeredAbility.TriggeredAbility Card.Card (GrantedAbility.GrantedAbility Card.Card),
    source :: ObjectId.ObjectId,
    controller :: PlayerId.PlayerId
  }
  deriving (Eq, Ord, Show)
