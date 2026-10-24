module Parun.Codec.Defense where

import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.Defense as Defense

codec :: Codec.Codec Defense.Defense
codec = Common.wrapper Common.natural Defense.MkDefense Defense.unwrap
