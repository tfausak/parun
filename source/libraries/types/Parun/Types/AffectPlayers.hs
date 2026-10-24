module Parun.Types.AffectPlayers where

import qualified Parun.Types.AffectedPlayers as AffectedPlayers
import qualified Parun.Types.Duration as Duration
import qualified Parun.Types.PlayerEffect as PlayerEffect
import qualified Parun.Types.SlotName as SlotName

-- | The payload of Parun.Types.Effect's AffectPlayers arm (#1305): install this
-- player effect over the players named, for this duration.
data AffectPlayers = MkAffectPlayers
  { duration :: Duration.Duration,
    players :: AffectedPlayers.AffectedPlayers SlotName.SlotName,
    effect :: PlayerEffect.PlayerEffect
  }
  deriving (Eq, Ord, Show)
