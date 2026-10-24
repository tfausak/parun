module Parun.Codec.Pile where

import qualified Parun.Codec.Timestamp as Timestamp
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.Pile as Pile

codec :: Codec.Codec Pile.Pile
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "OfForetold" Timestamp.codec Pile.OfForetold (\x -> case x of Pile.OfForetold y -> Just y; _ -> Nothing),
      Arm.payload "OfFaceDown" Timestamp.codec Pile.OfFaceDown (\x -> case x of Pile.OfFaceDown y -> Just y; _ -> Nothing)
    ]

tagOf :: Pile.Pile -> String
tagOf x = case x of
  Pile.OfForetold {} -> "OfForetold"
  Pile.OfFaceDown {} -> "OfFaceDown"
