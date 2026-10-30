module Parun.Types.ChangeTargets where

import qualified Parun.Types.ObjectRef as ObjectRef

-- | CR 115.7a / 115.7b: change the targets of each spell or ability on the
-- stack `objects` names, freely or to the one object `onto` names.
data ChangeTargets = MkChangeTargets
  { -- | The spells and abilities whose targets change.
    objects :: ObjectRef.ObjectRef,
    -- | Nothing: CR 115.7a, every target changes to one the resolving
    -- controller chooses (Deflection). Just: CR 115.7b, exactly one target, of
    -- the controller's choosing, changes to an object this names (Mizzium
    -- Meddler's "change a target ... to this creature").
    onto :: Maybe ObjectRef.ObjectRef
  }
  deriving (Eq, Ord, Show)
