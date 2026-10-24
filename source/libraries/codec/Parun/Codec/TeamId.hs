module Parun.Codec.TeamId where

import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.TeamId as TeamId

-- | A Natural rather than a bare Integer, Parun.Codec.PlayerId's reason: a
-- negative wire value cannot go through a partial fromInteger.
codec :: Codec.Codec TeamId.TeamId
codec = Common.wrapper Common.natural TeamId.MkTeamId TeamId.unwrap
