module Parun.Codec.CostOfferSpec where

import qualified Parun.Codec.CostOffer as CostOffer
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CostOffer as CostOffer.Type
import qualified Parun.Types.KeywordDesignator as KeywordDesignator
import qualified Parun.Types.KeywordFamily as KeywordFamily

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CostOffer" $ do
  Spec.it s "ByKeyword" $
    Common.assertCodec
      s
      CostOffer.codec
      (CostOffer.Type.ByKeyword (KeywordDesignator.OfFamily KeywordFamily.Blitz))
      " {\"type\":\"ByKeyword\",\"value\":{\"type\":\"OfFamily\",\"value\":{\"type\":\"Blitz\"}}} "
  Spec.it s "ByNoKeyword" $
    Common.assertCodec s CostOffer.codec CostOffer.Type.ByNoKeyword " {\"type\":\"ByNoKeyword\"} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s CostOffer.codec
