module Pawl.Codec.ManaSpecificationSpec where

import qualified Pawl.Codec.ManaSpecification as ManaSpecification
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.Color as Color
import qualified Pawl.Types.ManaSpecification as ManaSpecification

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.ManaSpecification" $ do
  Spec.it s "AnyMana" $
    Common.assertCodec
      s
      ManaSpecification.codec
      ManaSpecification.AnyMana
      " {\"type\":\"AnyMana\"} "
  Spec.it s "ChosenColor" $
    Common.assertCodec
      s
      ManaSpecification.codec
      ManaSpecification.ChosenColor
      " {\"type\":\"ChosenColor\"} "
  Spec.it s "OfColor" $
    Common.assertCodec
      s
      ManaSpecification.codec
      (ManaSpecification.OfColor Color.Red)
      " {\"type\":\"OfColor\",\"value\":{\"type\":\"Red\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s ManaSpecification.codec
