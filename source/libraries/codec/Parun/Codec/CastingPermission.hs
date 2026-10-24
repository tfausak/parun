module Parun.Codec.CastingPermission where

import qualified Parun.Codec.KeywordFamily as KeywordFamily
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.CastingPermission as CastingPermission

codec :: Codec.Codec CastingPermission.CastingPermission
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "CastFromLibraryWhileSearching" CastingPermission.CastFromLibraryWhileSearching,
      Arm.optionalPayload "CastFromGraveyard" KeywordFamily.codec CastingPermission.CastFromGraveyard (\x -> case x of CastingPermission.CastFromGraveyard y -> Just y; _ -> Nothing)
    ]

tagOf :: CastingPermission.CastingPermission -> String
tagOf x = case x of
  CastingPermission.CastFromLibraryWhileSearching {} -> "CastFromLibraryWhileSearching"
  CastingPermission.CastFromGraveyard {} -> "CastFromGraveyard"
