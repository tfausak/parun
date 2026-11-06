module Parun.Types.Surveil where

import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SlotName as SlotName

-- | The payload of Parun.Types.Effect's Surveil arm: Parun.Types.PlayerQuantity
-- plus where the cards it put into a graveyard are bound.
--
-- The `slot` is CR 608.2c's looking back: "If you put a noncreature, nonland
-- card into your graveyard this way, put that card into your hand" (Chandra,
-- Chill of Compliance) names the cards the surveil moved, and CR 400.7j finds
-- them in the public zone they arrived in. The ids bound are the ones the moves
-- ARRIVED at (CR 400.7), Parun.Types.Mill's `slot` posture, so a card a
-- replacement diverted out of the graveyard is bound too and the reader's
-- filter decides whether it went "into your graveyard". Absent for every
-- surveil nothing looks back at.
data Surveil = MkSurveil
  { player :: PlayerRef.PlayerRef,
    quantity :: Quantity.Quantity,
    slot :: Maybe SlotName.SlotName
  }
  deriving (Eq, Ord, Show)
