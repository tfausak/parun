module Parun.Codec.AloneUnlessSpec where

import qualified Parun.Codec.AloneUnless as AloneUnless
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Affected as Affected
import qualified Parun.Types.AloneUnless as AloneUnless
import qualified Parun.Types.Comparison as Comparison
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Measure as Measure
import qualified Parun.Types.Measures as Measures
import qualified Parun.Types.Operand as Operand

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AloneUnless" $ do
  -- CR 506.5's plain "alone": no key, which is how Bonded Construct's file
  -- already reads.
  Spec.it s "MkAloneUnless, alongside elided" $
    Common.assertCodec
      s
      AloneUnless.codec
      (AloneUnless.MkAloneUnless Affected.Attached Nothing Nothing Nothing)
      " {\"affected\":{\"type\":\"Attached\"}} "
  Spec.it s "MkAloneUnless, alongside written" $
    Common.assertCodec
      s
      AloneUnless.codec
      ( AloneUnless.MkAloneUnless
          { AloneUnless.affected = Affected.Matching Filter.IsSource,
            AloneUnless.alongside = Just (Filter.Measures (Measures.MkMeasures Measure.Power Comparison.GreaterThan (Operand.OfSource Measure.Power))),
            AloneUnless.unless = Nothing,
            AloneUnless.name = Nothing
          }
      )
      " {\"affected\":{\"type\":\"Matching\",\"value\":{\"type\":\"IsSource\"}},\"alongside\":{\"type\":\"Measures\",\"value\":{\"measure\":{\"type\":\"Power\"},\"comparison\":{\"type\":\"GreaterThan\"},\"operand\":{\"type\":\"OfSource\",\"value\":{\"type\":\"Power\"}}}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s AloneUnless.codec
