module Parun.Types.ModifyTarget where

import qualified Parun.Types.Duration as Duration
import qualified Parun.Types.Modification as Modification
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.SlotName as SlotName

-- | The payload of Parun.Types.Effect's ModifyTarget arm (#1305): apply this
-- modification to the objects the ObjectRef names, for this duration.
--
-- Parametric in `ability` for Parun.Types.Modification's reason, and it is the
-- same variable Parun.Types.Effect threads down to here: this module cannot NAME
-- an ability, because an ability carries Effects and an Effect carries one of
-- these, so a concrete Parun.Types.GrantedAbility here would close a module
-- cycle. Parun.Types.GrantedAbility ties the knot instead, exactly as
-- Parun.Types.Card ties the `card` one -- which is what lets a card worded
-- "target creature gains '[ability]' until end of turn" resolve into the same
-- Modification a printed static ability grants.
data ModifyTarget ability = MkModifyTarget
  { duration :: Duration.Duration,
    modification :: Modification.Modification ability,
    ref :: ObjectRef.ObjectRef,
    -- | The name each affected object is bound under while the modification's
    -- quantities are frozen, so each gets its own value (CR 701.10b's "that
    -- creature's power"): one stored effect per object. Nothing freezes once,
    -- against the source. Proved by data/scenarios/power-toughness/'s
    -- cr-701-10b-611-2c God-Eternal Rhonas scenario.
    each :: Maybe SlotName.SlotName
  }
  deriving (Eq, Ord, Show)
