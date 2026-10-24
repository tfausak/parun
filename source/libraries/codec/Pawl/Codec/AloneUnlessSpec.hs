module Pawl.Codec.AloneUnlessSpec where

import qualified Pawl.Codec.AloneUnless as AloneUnless
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.Affected as Affected
import qualified Pawl.Types.AloneUnless as AloneUnless
import qualified Pawl.Types.Comparison as Comparison
import qualified Pawl.Types.Filter as Filter
import qualified Pawl.Types.Measure as Measure
import qualified Pawl.Types.Measures as Measures
import qualified Pawl.Types.Operand as Operand

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.AloneUnless" $ do
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
