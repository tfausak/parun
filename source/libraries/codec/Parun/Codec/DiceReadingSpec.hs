module Parun.Codec.DiceReadingSpec where

import qualified Parun.Codec.DiceReading as DiceReading
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.DiceReading as DiceReading

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.DiceReading" $ do
  Spec.it s "ChooseOne" $
    Common.assertCodec
      s
      DiceReading.codec
      DiceReading.ChooseOne
      " \"ChooseOne\" "
  Spec.it s "Total" $
    Common.assertCodec
      s
      DiceReading.codec
      DiceReading.Total
      " \"Total\" "
  Spec.it s "Both" $
    Common.assertCodec
      s
      DiceReading.codec
      DiceReading.Both
      " \"Both\" "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s DiceReading.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s DiceReading.codec
