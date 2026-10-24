module Parun.Codec.ClassLevel where

import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.ClassLevel as ClassLevel

codec :: Codec.Codec ClassLevel.ClassLevel
codec = Common.wrapper Common.natural ClassLevel.MkClassLevel ClassLevel.unwrap
