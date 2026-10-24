module Parun.Codec.Teams where

import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.Codec.TeamId as TeamId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.Teams as Teams

-- | Keyed by a PlayerId, a Natural newtype, so it takes 'Common.naturalMap'.
codec :: Codec.Codec Teams.Teams
codec = Common.wrapper (Common.naturalMap PlayerId.codec TeamId.codec) Teams.MkTeams Teams.unwrap
