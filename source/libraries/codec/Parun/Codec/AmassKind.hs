module Parun.Codec.AmassKind where

import qualified Parun.Codec.Subtype as Subtype
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.AmassKind as AmassKind

codec :: Codec.Codec AmassKind.AmassKind
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "Army" Subtype.codec AmassKind.Army (\x -> case x of AmassKind.Army y -> Just y; _ -> Nothing),
      Arm.nullary "EmpowerJace" AmassKind.EmpowerJace
    ]

tagOf :: AmassKind.AmassKind -> String
tagOf x = case x of
  AmassKind.Army {} -> "Army"
  AmassKind.EmpowerJace {} -> "EmpowerJace"
