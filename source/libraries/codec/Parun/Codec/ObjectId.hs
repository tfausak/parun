module Parun.Codec.ObjectId where

import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.ObjectId as ObjectId

codec :: Codec.Codec ObjectId.ObjectId
codec = Common.wrapper Common.natural ObjectId.MkObjectId ObjectId.unwrap
