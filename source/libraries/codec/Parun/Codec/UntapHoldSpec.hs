module Parun.Codec.UntapHoldSpec where

import qualified Data.List.NonEmpty as NonEmpty
import qualified Parun.Codec.UntapHold as UntapHold
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.UntapHold as UntapHold

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.UntapHold" $ do
  Spec.it s "Forbidden" $
    Common.assertCodec
      s
      UntapHold.codec
      UntapHold.Forbidden
      " {\"type\":\"Forbidden\"} "
  Spec.it s "Elective" $
    Common.assertCodec
      s
      UntapHold.codec
      UntapHold.Elective
      " {\"type\":\"Elective\"} "
  Spec.it s "AtMost" $
    Common.assertCodec
      s
      UntapHold.codec
      (UntapHold.AtMost 2)
      " {\"type\":\"AtMost\",\"value\":2} "
  Spec.it s "DuringOthersSteps" $
    Common.assertCodec
      s
      UntapHold.codec
      UntapHold.DuringOthersSteps
      " {\"type\":\"DuringOthersSteps\"} "
  Spec.it s "OfChosenType" $
    Common.assertCodec
      s
      UntapHold.codec
      (UntapHold.OfChosenType (CardType.Artifact NonEmpty.:| [CardType.Land]))
      " {\"type\":\"OfChosenType\",\"value\":[{\"type\":\"Artifact\"},{\"type\":\"Land\"}]} "
  Spec.it s "Never" $
    Common.assertCodec
      s
      UntapHold.codec
      UntapHold.Never
      " {\"type\":\"Never\"} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s UntapHold.codec
