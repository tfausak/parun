module Parun.Types.Tap where

import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.SlotName as SlotName

-- | The payload of Parun.Types.Effect's Tap arm (CR 701.26a).
data Tap = MkTap
  { ref :: ObjectRef.ObjectRef,
    -- | Where the permanents this tap turned sideways are bound, as a group --
    -- Master of the Wild Hunt's "each Wolf tapped this way". Nothing is bound
    -- when nothing was tapped.
    tapped :: Maybe SlotName.SlotName
  }
  deriving (Eq, Ord, Show)

-- | Tap what the ObjectRef names, binding nothing.
plain :: ObjectRef.ObjectRef -> Tap
plain r = MkTap {ref = r, tapped = Nothing}
