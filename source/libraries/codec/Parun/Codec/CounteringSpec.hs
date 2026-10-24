module Parun.Codec.CounteringSpec where

import qualified Parun.Codec.Countering as Countering
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Countering as Countering
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId

spec :: (Monad m) => Spec.Spec m n -> n ()
spec s =
  Spec.describe s "Parun.Codec.Countering" . Spec.it s "MkCountering" $
    Common.assertCodec
      s
      Countering.codec
      Countering.MkCountering
        { Countering.countered = ObjectId.MkObjectId 4,
          Countering.source = ObjectId.MkObjectId 5,
          Countering.controller = PlayerId.MkPlayerId 1
        }
      " {\"countered\":4,\"source\":5,\"controller\":1} "
