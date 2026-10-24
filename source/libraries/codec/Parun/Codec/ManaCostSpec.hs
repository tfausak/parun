module Parun.Codec.ManaCostSpec where

import qualified Parun.Codec.ManaCost as ManaCost
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Color as Color
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaSymbol as ManaSymbol
import qualified Parun.Types.ManaType as ManaType

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ManaCost" $ do
  Spec.it s "MkManaCost" $
    Common.assertCodec
      s
      ManaCost.codec
      (ManaCost.MkManaCost [ManaSymbol.Generic 1, ManaSymbol.OfType (ManaType.Colored Color.Red)])
      " [{\"type\":\"Generic\",\"value\":1},{\"type\":\"OfType\",\"value\":{\"type\":\"Colored\",\"value\":{\"type\":\"Red\"}}}] "
  -- CR 118.5a: {0} is a real, payable cost, and ManaCost's empty list IS {0} --
  -- so the empty array has to round-trip, not just a nonempty one.
  Spec.it s "MkManaCost []" $
    Common.assertCodec
      s
      ManaCost.codec
      (ManaCost.MkManaCost [])
      " [] "
  Spec.it s "has a schema" $
    Common.assertHasSchema s ManaCost.codec
