module Parun.Codec.CardName where

import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.CardName as CardName

codec :: Codec.Codec CardName.CardName
codec = Common.wrapper Common.text CardName.MkCardName CardName.unwrap
