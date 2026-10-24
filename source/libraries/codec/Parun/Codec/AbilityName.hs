module Parun.Codec.AbilityName where

import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.AbilityName as AbilityName

codec :: Codec.Codec AbilityName.AbilityName
codec = Common.wrapper Common.text AbilityName.MkAbilityName AbilityName.unwrap
