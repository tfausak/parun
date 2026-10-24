module Parun.Codec.PlayerChoice where

import qualified Parun.Codec.Gift as Gift
import qualified Parun.Codec.KeywordInstance as KeywordInstance
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.PlayerChoice as PlayerChoice

codec :: Codec.Codec PlayerChoice.PlayerChoice
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "AsEnters" PlayerChoice.AsEnters,
      Arm.payload "Promised" (Common.tuple Gift.codec KeywordInstance.codec) (uncurry PlayerChoice.Promised) (\x -> case x of PlayerChoice.Promised g n -> Just (g, n); _ -> Nothing)
    ]

tagOf :: PlayerChoice.PlayerChoice -> String
tagOf x = case x of
  PlayerChoice.AsEnters {} -> "AsEnters"
  PlayerChoice.Promised {} -> "Promised"
