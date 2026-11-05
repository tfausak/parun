module Parun.Types.PayerAnswer where

import qualified Data.Set as Set
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.ObjectId as ObjectId

-- | CR 101.4b: what a later payer of one offer is told an earlier payer
-- answered.
data PayerAnswer
  = -- | Declined, or could not pay (CR 118.3).
    Declined
  | -- | Paid with this option, taking these objects; a card chosen from a
    -- hidden zone is not named (CR 101.4a).
    Paid (Cost.Cost Keyword.Keyword) (Set.Set ObjectId.ObjectId)
  deriving (Eq, Ord, Show)
