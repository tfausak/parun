module Parun.Codec.InstanceOrdinal where

import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.InstanceOrdinal as InstanceOrdinal

codec :: Codec.Codec InstanceOrdinal.InstanceOrdinal
codec = Common.wrapper Common.natural InstanceOrdinal.MkInstanceOrdinal InstanceOrdinal.unwrap
