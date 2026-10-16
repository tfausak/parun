module Pawl.Codec.PlayerChoice where

import qualified Pawl.Codec.Gift as Gift
import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Types.PlayerChoice as PlayerChoice

codec :: Codec.Codec PlayerChoice.PlayerChoice
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "AsEnters" PlayerChoice.AsEnters,
      Arm.payload "Promised" (Common.tuple Gift.codec Common.natural) (uncurry PlayerChoice.Promised) (\x -> case x of PlayerChoice.Promised g n -> Just (g, n); _ -> Nothing)
    ]

tagOf :: PlayerChoice.PlayerChoice -> String
tagOf x = case x of
  PlayerChoice.AsEnters {} -> "AsEnters"
  PlayerChoice.Promised {} -> "Promised"
