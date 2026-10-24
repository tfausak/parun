module Parun.Types.ContinuousEffect where

import qualified Parun.Types.Affected as Affected
import qualified Parun.Types.Expiry as Expiry
import qualified Parun.Types.GrantedAbility as GrantedAbility
import qualified Parun.Types.Modification as Modification
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.Timestamp as Timestamp

-- | A stored continuous effect (CR 611.2), held in GameState.continuousEffects.
-- `timestamp` orders it within its layer (CR 613.7); `expiry` decides when a
-- sweep drops it (Parun.Engine.Expiry; CR 514.2, 611.2a, 611.2b); `affected` is
-- its fixed set (CR 611.2c). Static-ability effects are NOT stored here -- they
-- are re-derived each projection, from the object's copiable static abilities
-- (Parun.Engine.Projection.View.staticAbilitiesOf).
--
-- Made by a spell or ability RESOLVING, all but two of them. One exception is
-- CR 106.6a's rider effect, which is created as the mana is SPENT and so lands
-- inside a cost payment (Parun.Engine.ManaRider.granted, from
-- Parun.Engine.Cost.recordPayment). The other is the one clause that turns a
-- static ability's effect into a stored one:
-- StaticAbility.lingers, Titania's Song's "if this enchantment leaves the
-- battlefield, this effect continues until end of turn", which
-- Parun.Engine.Event.lingeringHandover hands over as the permanent goes -- by a
-- zone change, with its owner under CR 800.4a, or into a subgame's wish under
-- CR 729.4a. Such an effect keeps the timestamp CR 613.7a gave it rather than
-- taking a fresh one, since the card says it is the same effect continuing.
--
-- Parametric in `card` for Parun.Types.StaticAbility's reason, and instantiated at
-- the SAME width: the lingers clause hands a static ability's own modification
-- over here, so this position has to hold a granted ability. What a RESOLUTION
-- stores arrives narrower (Parun.Types.ModifyTarget) and is widened on the way in.
data ContinuousEffect card = MkContinuousEffect
  { source :: ObjectId.ObjectId,
    timestamp :: Timestamp.Timestamp,
    expiry :: Expiry.Expiry,
    modification :: Modification.Modification (GrantedAbility.GrantedAbility card),
    affected :: Affected.Affected
  }
  deriving (Eq, Ord, Show)
