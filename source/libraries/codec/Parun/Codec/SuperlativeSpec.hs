module Parun.Codec.SuperlativeSpec where

import qualified Parun.Codec.Superlative as Superlative
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Comparison as Comparison
import qualified Parun.Types.PlayerCounterKind as PlayerCounterKind
import qualified Parun.Types.PlayerMeasure as PlayerMeasure
import qualified Parun.Types.Superlative as Superlative

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Superlative" $ do
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
