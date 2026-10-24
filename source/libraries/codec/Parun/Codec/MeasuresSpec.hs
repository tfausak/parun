module Parun.Codec.MeasuresSpec where

import qualified Parun.Codec.Measures as Measures
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Comparison as Comparison
import qualified Parun.Types.Measure as Measure
import qualified Parun.Types.Measures as Measures
import qualified Parun.Types.Operand as Operand

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Measures" $ do
  -- Two different measures, so a codec reading the operand's measure as the
  -- candidate's goes red.
  Spec.it s "MkMeasures" $
    Common.assertCodec
      s
      Measures.codec
      (Measures.MkMeasures Measure.Power Comparison.AtLeast (Operand.OfSource Measure.Toughness))
      " {\"measure\":{\"type\":\"Power\"},\"comparison\":{\"type\":\"AtLeast\"},\"operand\":{\"type\":\"OfSource\",\"value\":{\"type\":\"Toughness\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s Measures.codec
