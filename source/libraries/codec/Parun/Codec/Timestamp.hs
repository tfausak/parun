module Parun.Codec.Timestamp where

import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.Timestamp as Timestamp

codec :: Codec.Codec Timestamp.Timestamp
codec = Common.wrapper Common.natural Timestamp.MkTimestamp Timestamp.unwrap
