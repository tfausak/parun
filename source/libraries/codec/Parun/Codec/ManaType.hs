module Parun.Codec.ManaType where

import qualified Parun.Codec.Color as Color
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.ManaType as ManaType

codec :: Codec.Codec ManaType.ManaType
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "Colored" Color.codec ManaType.Colored (\x -> case x of ManaType.Colored y -> Just y; _ -> Nothing),
      Arm.nullary "Colorless" ManaType.Colorless
    ]

tagOf :: ManaType.ManaType -> String
tagOf x = case x of
  ManaType.Colored {} -> "Colored"
  ManaType.Colorless {} -> "Colorless"
