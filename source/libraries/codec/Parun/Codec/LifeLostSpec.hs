module Parun.Codec.LifeLostSpec where

import qualified Parun.Codec.LifeLost as LifeLost
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.LifeLost as LifeLost
import qualified Parun.Types.PlayerId as PlayerId

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.LifeLost" $ do
  Spec.it s "MkLifeLost" $
    Common.assertCodec
      s
      LifeLost.codec
      (LifeLost.MkLifeLost (PlayerId.MkPlayerId 1) 2 False)
      " {\"player\":1,\"amount\":2,\"first\":false} "
  Spec.it s "has a schema" $ Common.assertHasSchema s LifeLost.codec
