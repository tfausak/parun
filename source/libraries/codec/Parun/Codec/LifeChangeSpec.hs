module Parun.Codec.LifeChangeSpec where

import qualified Parun.Codec.LifeChange as LifeChange
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.LifeChange as LifeChange
import qualified Parun.Types.PlayerId as PlayerId

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.LifeChange" $ do
  -- CR 119.3.
  Spec.it s "MkLifeChange, both keys" $
    Common.assertCodec
      s
      LifeChange.codec
      (LifeChange.MkLifeChange {LifeChange.player = PlayerId.MkPlayerId 0, LifeChange.amount = 3})
      " {\"player\":0,\"amount\":3} "
  Spec.it s "has a schema" $ Common.assertHasSchema s LifeChange.codec
