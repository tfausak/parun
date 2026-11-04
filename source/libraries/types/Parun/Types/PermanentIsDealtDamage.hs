module Parun.Types.PermanentIsDealtDamage where

import qualified Parun.Types.ActingPermanent as ActingPermanent
import qualified Parun.Types.Batching as Batching
import qualified Parun.Types.DealtDamage as DealtDamage

-- | CR 120.3 / 603.2c: which permanent's damage fires the ability, and whether
-- each source's damage is its own occurrence.
data PermanentIsDealtDamage = MkPermanentIsDealtDamage
  { dealt :: DealtDamage.DealtDamage ActingPermanent.ActingPermanent,
    -- | OneOrMore for "is dealt damage": one occurrence per damaged permanent
    -- per simultaneous batch (Ripjaw Raptor's and Fungusaur's rulings).
    -- EachOccurrence for "a source deals damage to": one per damage event, so
    -- per source (Belltower Sphinx).
    batching :: Batching.Batching
  }
  deriving (Eq, Ord, Show)
