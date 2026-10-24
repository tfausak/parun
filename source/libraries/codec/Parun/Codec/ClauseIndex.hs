module Parun.Codec.ClauseIndex where

import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.ClauseIndex as ClauseIndex

codec :: Codec.Codec ClauseIndex.ClauseIndex
codec = Common.wrapper Common.natural ClauseIndex.MkClauseIndex ClauseIndex.unwrap
