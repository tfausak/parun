module Parun.Types.ObjectCount where

import qualified Parun.Types.CostAmount as CostAmount

-- | How many matching objects a cost takes: Parun.Types.Sacrifice's
-- permanents, Parun.Types.DiscardCards' cards.
data ObjectCount
  = -- | This many, chosen by the payer: Cathartic Reunion's "Discard two cards".
    Exactly CostAmount.CostAmount
  | -- | Every matching object, so nothing is chosen and none is needed: Slate of
    -- Ancestry's "Discard your hand" (CR 701.9a), Soulblast's "sacrifice all
    -- creatures you control" (CR 701.21a).
    Every
  deriving (Eq, Ord, Show)
