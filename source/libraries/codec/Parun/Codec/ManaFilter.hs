module Parun.Codec.ManaFilter where

import qualified Parun.Codec.ManaType as ManaType
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.ManaFilter as ManaFilter

codec :: Codec.Codec ManaFilter.ManaFilter
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "Any" ManaFilter.Any,
      Arm.payload "OfType" ManaType.codec ManaFilter.OfType (\x -> case x of ManaFilter.OfType y -> Just y; _ -> Nothing),
      Arm.payload "NotOfType" ManaType.codec ManaFilter.NotOfType (\x -> case x of ManaFilter.NotOfType y -> Just y; _ -> Nothing)
    ]

tagOf :: ManaFilter.ManaFilter -> String
tagOf x = case x of
  ManaFilter.Any {} -> "Any"
  ManaFilter.OfType {} -> "OfType"
  ManaFilter.NotOfType {} -> "NotOfType"
