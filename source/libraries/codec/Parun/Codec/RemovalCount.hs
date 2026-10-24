module Parun.Codec.RemovalCount where

import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.RemovalCount as RemovalCount

-- | The tag that picks an arm is written by Parun.Codec.RemoveCountersAmong's
-- `count` field.
codec :: Codec.Codec RemovalCount.RemovalCount
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "Exactly" Quantity.codec RemovalCount.Exactly (\x -> case x of RemovalCount.Exactly y -> Just y; _ -> Nothing),
      Arm.payload "UpTo" Quantity.codec RemovalCount.UpTo (\x -> case x of RemovalCount.UpTo y -> Just y; _ -> Nothing),
      Arm.nullary "AnyNumber" RemovalCount.AnyNumber
    ]

tagOf :: RemovalCount.RemovalCount -> String
tagOf x = case x of
  RemovalCount.Exactly {} -> "Exactly"
  RemovalCount.UpTo {} -> "UpTo"
  RemovalCount.AnyNumber {} -> "AnyNumber"
