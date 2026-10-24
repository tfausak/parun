module Parun.Codec.ModeIndex where

import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.ModeIndex as ModeIndex

codec :: Codec.Codec ModeIndex.ModeIndex
codec = Common.wrapper Common.natural ModeIndex.MkModeIndex ModeIndex.unwrap
