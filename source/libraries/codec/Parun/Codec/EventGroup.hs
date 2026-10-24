module Parun.Codec.EventGroup where

import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.EventGroup as EventGroup

codec :: Codec.Codec EventGroup.EventGroup
codec = Common.wrapper Common.natural EventGroup.MkEventGroup EventGroup.unwrap
