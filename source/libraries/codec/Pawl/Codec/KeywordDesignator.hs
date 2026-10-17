module Pawl.Codec.KeywordDesignator where

import qualified Data.Typeable as Typeable
import qualified Pawl.Codec.KeywordFamily as KeywordFamily
import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Types.KeywordDesignator as KeywordDesignator

-- | Tagged, so `{"type":"OfFamily","value":{"type":"Cycling"}}` names CR 702.29a's
-- family and `{"type":"OfKeyword","value":{"type":"Exhaust"}}` names CR 702.177a's
-- keyword. The keyword codec is a PARAMETER; see Pawl.Codec.Filter's header.
codec :: (Typeable.Typeable keyword) => Codec.Codec keyword -> Codec.Codec (KeywordDesignator.KeywordDesignator keyword)
codec keywordCodec =
  Arm.tagged
    tagOf
    [ Arm.payload "OfFamily" KeywordFamily.codec KeywordDesignator.OfFamily (\x -> case x of KeywordDesignator.OfFamily y -> Just y; _ -> Nothing),
      Arm.payload "OfKeyword" keywordCodec KeywordDesignator.OfKeyword (\x -> case x of KeywordDesignator.OfKeyword y -> Just y; _ -> Nothing),
      Arm.payload "Printed" KeywordFamily.codec KeywordDesignator.Printed (\x -> case x of KeywordDesignator.Printed y -> Just y; _ -> Nothing),
      Arm.payload "OfInstance" (Common.tuple keywordCodec Common.natural) (uncurry KeywordDesignator.OfInstance) (\x -> case x of KeywordDesignator.OfInstance k n -> Just (k, n); _ -> Nothing)
    ]

tagOf :: KeywordDesignator.KeywordDesignator keyword -> String
tagOf x = case x of
  KeywordDesignator.OfFamily {} -> "OfFamily"
  KeywordDesignator.OfKeyword {} -> "OfKeyword"
  KeywordDesignator.Printed {} -> "Printed"
  KeywordDesignator.OfInstance {} -> "OfInstance"
