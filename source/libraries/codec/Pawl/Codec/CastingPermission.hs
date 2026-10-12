module Pawl.Codec.CastingPermission where

import qualified Pawl.Codec.KeywordFamily as KeywordFamily
import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.Types.CastingPermission as CastingPermission

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
