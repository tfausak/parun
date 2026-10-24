module Parun.Codec.Decider where

import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.Decider as Decider

codec :: Codec.Codec Decider.Decider
codec = Common.wrapper PlayerId.codec Decider.MkDecider Decider.unwrap
