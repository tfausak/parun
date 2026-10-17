module Pawl.Codec.SuperlativeSpec where

import qualified Pawl.Codec.Superlative as Superlative
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.Comparison as Comparison
import qualified Pawl.Types.PlayerCounterKind as PlayerCounterKind
import qualified Pawl.Types.PlayerMeasure as PlayerMeasure
import qualified Pawl.Types.Superlative as Superlative

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.Superlative" $ do
  -- Damping Engine's strict lead on permanents.
  Spec.it s "PermanentsControlled, strict" $
    Common.assertCodec
      s
      Superlative.codec
      (Superlative.MkSuperlative {Superlative.measure = PlayerMeasure.PermanentsControlled, Superlative.comparison = Comparison.GreaterThan})
      " {\"measure\":{\"type\":\"PermanentsControlled\"},\"comparison\":{\"type\":\"GreaterThan\"}} "
  -- Raiders' Allegiance's "the most point counters or tied for the most".
  Spec.it s "CountersOf, ties included" $
    Common.assertCodec
      s
      Superlative.codec
      (Superlative.MkSuperlative {Superlative.measure = PlayerMeasure.CountersOf PlayerCounterKind.Point, Superlative.comparison = Comparison.AtLeast})
      " {\"measure\":{\"type\":\"CountersOf\",\"value\":{\"type\":\"Point\"}},\"comparison\":{\"type\":\"AtLeast\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s Superlative.codec
