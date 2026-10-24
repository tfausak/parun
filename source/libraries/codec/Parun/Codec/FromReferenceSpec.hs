module Parun.Codec.FromReferenceSpec where

import qualified Parun.Codec.FromReference as FromReference
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Comparison as Comparison
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.FromReference as FromReference
import qualified Parun.Types.Measure as Measure
import qualified Parun.Types.Measures as Measures
import qualified Parun.Types.Operand as Operand
import qualified Parun.Types.Quantity as Quantity

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.FromReference" $ do
  Spec.it s "MkFromReference, no amount" $
    Common.assertCodec
      s
      FromReference.codec
      (FromReference.MkFromReference (Filter.HasCardType CardType.Creature) Nothing)
      " {\"filter\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}} "
  Spec.it s "MkFromReference, an amount" $
    Common.assertCodec
      s
      FromReference.codec
      (FromReference.MkFromReference (Filter.Measures (Measures.MkMeasures Measure.ManaValue Comparison.Exactly Operand.EnclosingAmount)) (Just (Quantity.Literal 3)))
      " {\"amount\":{\"type\":\"Literal\",\"value\":3},\"filter\":{\"type\":\"Measures\",\"value\":{\"measure\":{\"type\":\"ManaValue\"},\"comparison\":{\"type\":\"Exactly\"},\"operand\":{\"type\":\"EnclosingAmount\"}}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s FromReference.codec
