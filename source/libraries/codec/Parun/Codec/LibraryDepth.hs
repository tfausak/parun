module Parun.Codec.LibraryDepth where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.LibraryDepth as LibraryDepth

codec :: Codec.Codec LibraryDepth.LibraryDepth
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "FromTop" Common.natural LibraryDepth.FromTop (\x -> case x of LibraryDepth.FromTop y -> Just y; _ -> Nothing),
      Arm.payload "AtRandomInTop" Common.natural LibraryDepth.AtRandomInTop (\x -> case x of LibraryDepth.AtRandomInTop y -> Just y; _ -> Nothing)
    ]

tagOf :: LibraryDepth.LibraryDepth -> String
tagOf x = case x of
  LibraryDepth.FromTop {} -> "FromTop"
  LibraryDepth.AtRandomInTop {} -> "AtRandomInTop"
