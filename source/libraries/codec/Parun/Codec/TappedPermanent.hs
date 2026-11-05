module Parun.Codec.TappedPermanent where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.TappedPermanent as TappedPermanent

codec :: Codec.Codec TappedPermanent.TappedPermanent
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "Attached" TappedPermanent.Attached,
      Arm.payload "Matching" (Filter.codec Keyword.codec) TappedPermanent.Matching (\x -> case x of TappedPermanent.Matching y -> Just y; _ -> Nothing)
    ]

tagOf :: TappedPermanent.TappedPermanent -> String
tagOf x = case x of
  TappedPermanent.Attached {} -> "Attached"
  TappedPermanent.Matching {} -> "Matching"
