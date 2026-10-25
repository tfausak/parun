module Parun.Types.TargetChooser where

import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.SlotName as SlotName

-- | CR 115.1 / 601.2c: WHO announces a target slot's targets when it is not the
-- ability's controller -- Parun.Types.TargetSlot's `chooser`, resolved to a seat
-- by Parun.Engine.Target.chooserOf.
data TargetChooser
  = -- | A seat standing in this relation to the controller -- Cuombajj Witches'
    -- "of an opponent's choice"; where it admits several, the controller picks
    -- (CR 801.5a's example).
    Relative PlayerRelation.PlayerRelation
  | -- | The player a binding the announcement already holds names -- Curse of
    -- Inertia's "that attacking player ... target permanent of their choice",
    -- the trigger event's player bound before CR 603.3d's announcement.
    InSlot SlotName.SlotName
  | -- | CR 110.2 / 608.2h: the controller of the object a binding names, read
    -- through last-known information -- Necrotic Plague's "its controller
    -- chooses", the creature that died.
    ControllerOfBound SlotName.SlotName
  deriving (Eq, Ord, Show)
