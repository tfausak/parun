module Parun.Codec.Label where

import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.Label as Label

codec :: Codec.Codec Label.Label
codec = Common.wrapper Common.text Label.MkLabel Label.unwrap
