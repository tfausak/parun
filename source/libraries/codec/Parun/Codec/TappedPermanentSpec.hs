module Parun.Codec.TappedPermanentSpec where

import qualified Parun.Codec.TappedPermanent as TappedPermanent
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.TappedPermanent as TappedPermanent

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.TappedPermanent" $ do
  Spec.it s "Attached" $
    Common.assertCodec s TappedPermanent.codec TappedPermanent.Attached " {\"type\":\"Attached\"} "
  Spec.it s "Matching" $
    Common.assertCodec s TappedPermanent.codec (TappedPermanent.Matching (Filter.HasCardType CardType.Land)) " {\"type\":\"Matching\",\"value\":{\"type\":\"HasCardType\",\"value\":\"Land\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s TappedPermanent.codec
