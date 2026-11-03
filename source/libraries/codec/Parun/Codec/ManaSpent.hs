module Parun.Codec.ManaSpent where

import qualified Parun.Codec.ManaType as ManaType
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.ManaSpent as ManaSpent

codec :: Codec.Codec ManaSpent.ManaSpent
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "Total" ManaSpent.Total,
      Arm.payload "OfTypeOnX" ManaType.codec ManaSpent.OfTypeOnX (\x -> case x of ManaSpent.OfTypeOnX y -> Just y; _ -> Nothing)
    ]

tagOf :: ManaSpent.ManaSpent -> String
tagOf x = case x of
  ManaSpent.Total {} -> "Total"
  ManaSpent.OfTypeOnX {} -> "OfTypeOnX"
