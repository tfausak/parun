module Parun.Codec.CounteredEnd where

import qualified Parun.Codec.LibraryPosition as LibraryPosition
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.CounteredEnd as CounteredEnd

codec :: Codec.Codec CounteredEnd.CounteredEnd
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "Stated" LibraryPosition.codec CounteredEnd.Stated (\x -> case x of CounteredEnd.Stated y -> Just y; _ -> Nothing),
      Arm.nullary "CounteringPlayerChooses" CounteredEnd.CounteringPlayerChooses
    ]

tagOf :: CounteredEnd.CounteredEnd -> String
tagOf x = case x of
  CounteredEnd.Stated {} -> "Stated"
  CounteredEnd.CounteringPlayerChooses {} -> "CounteringPlayerChooses"
