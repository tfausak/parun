module Parun.Codec.DrewSpec where

import qualified Parun.Codec.Drew as Drew
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Drew as Drew
import qualified Parun.Types.PlayerId as PlayerId

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Drew" $ do
  -- CR 121.1, and WHICH draw of the turn it was.
  Spec.it s "MkDrew, both keys" $
    Common.assertCodec
      s
      Drew.codec
      (Drew.MkDrew {Drew.player = PlayerId.MkPlayerId 0, Drew.nth = 2})
      " {\"player\":0,\"nth\":2} "
  Spec.it s "has a schema" $ Common.assertHasSchema s Drew.codec
