module Parun.Codec.OutsideCard where

import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PrintingId as PrintingId
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.OutsideCard as OutsideCard

-- | Reached through Parun.Codec.Player's `companion` key.
codec :: Codec.Codec OutsideCard.OutsideCard
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "InPool" PrintingId.codec OutsideCard.InPool (\x -> case x of OutsideCard.InPool y -> Just y; _ -> Nothing),
      Arm.payload "InAnotherGame" ObjectId.codec OutsideCard.InAnotherGame (\x -> case x of OutsideCard.InAnotherGame y -> Just y; _ -> Nothing)
    ]

tagOf :: OutsideCard.OutsideCard -> String
tagOf x = case x of
  OutsideCard.InPool {} -> "InPool"
  OutsideCard.InAnotherGame {} -> "InAnotherGame"
