module Parun.Codec.ManaSpentSpec where

import qualified Parun.Codec.ManaSpent as ManaSpent
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Color as Color
import qualified Parun.Types.ManaSpent as ManaSpent
import qualified Parun.Types.ManaType as ManaType

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ManaSpent" $ do
  Spec.it s "Total" $
    Common.assertCodec s ManaSpent.codec ManaSpent.Total " {\"type\":\"Total\"} "
  Spec.it s "OfTypeOnX" $
    Common.assertCodec
      s
      ManaSpent.codec
      (ManaSpent.OfTypeOnX (ManaType.Colored Color.Black))
      " {\"type\":\"OfTypeOnX\",\"value\":{\"type\":\"Colored\",\"value\":{\"type\":\"Black\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s ManaSpent.codec
