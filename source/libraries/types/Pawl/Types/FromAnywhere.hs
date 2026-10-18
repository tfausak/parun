module Pawl.Types.FromAnywhere where

import qualified Pawl.Types.SlotName as SlotName

-- | CR 400.7: the object a slot holds, followed to wherever it is now --
-- Timmerian Fiends' "Timmerian Fiends from anywhere".
--
-- The fields are named rather than positional, the shape every other
-- Pawl.Types.ObjectRef payload record takes.
data FromAnywhere = MkFromAnywhere
  { slot :: SlotName.SlotName,
    -- | CR 400.7j: only an incarnation this other slot also holds -- Bronze
    -- Tablet's "this card", the member of its one exile (CR 608.2f) that was
    -- the Tablet, and nothing where the Tablet was not exiled.
    among :: Maybe SlotName.SlotName
  }
  deriving (Eq, Ord, Show)
