module Parun.Codec.CostOffer where

import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.KeywordDesignator as KeywordDesignator
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.CostOffer as CostOffer

codec :: Codec.Codec CostOffer.CostOffer
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "ByKeyword" (KeywordDesignator.codec Keyword.codec) CostOffer.ByKeyword (\x -> case x of CostOffer.ByKeyword y -> Just y; _ -> Nothing),
      Arm.nullary "ByNoKeyword" CostOffer.ByNoKeyword
    ]

tagOf :: CostOffer.CostOffer -> String
tagOf x = case x of
  CostOffer.ByKeyword {} -> "ByKeyword"
  CostOffer.ByNoKeyword -> "ByNoKeyword"
