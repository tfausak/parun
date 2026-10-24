module Parun.Codec.ExileLooker where

import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.ExileLooker as ExileLooker

-- | Tagged rather than an enum: CR 406.3's grant names a seat and CR 702.75a's
-- names none.
codec :: Codec.Codec ExileLooker.ExileLooker
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "ThePlayer" PlayerId.codec ExileLooker.ThePlayer (\x -> case x of ExileLooker.ThePlayer y -> Just y; _ -> Nothing),
      Arm.nullary "TheExiler" ExileLooker.TheExiler
    ]

tagOf :: ExileLooker.ExileLooker -> String
tagOf x = case x of
  ExileLooker.ThePlayer {} -> "ThePlayer"
  ExileLooker.TheExiler {} -> "TheExiler"
