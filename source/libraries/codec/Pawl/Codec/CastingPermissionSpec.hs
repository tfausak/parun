module Pawl.Codec.CastingPermissionSpec where

import qualified Pawl.Codec.CastingPermission as CastingPermission
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.CastingPermission as CastingPermission
import qualified Pawl.Types.KeywordFamily as KeywordFamily

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.CastingPermission" $ do
  Spec.it s "CastFromLibraryWhileSearching" $
    Common.assertCodec
      s
      CastingPermission.codec
      CastingPermission.CastFromLibraryWhileSearching
      " {\"type\":\"CastFromLibraryWhileSearching\"} "
  Spec.it s "CastFromGraveyard" $
    Common.assertCodec
      s
      CastingPermission.codec
      (CastingPermission.CastFromGraveyard Nothing)
      " {\"type\":\"CastFromGraveyard\"} "
  Spec.it s "CastFromGraveyard using a keyword" $
    Common.assertCodec
      s
      CastingPermission.codec
      (CastingPermission.CastFromGraveyard (Just KeywordFamily.Blitz))
      " {\"type\":\"CastFromGraveyard\",\"value\":{\"type\":\"Blitz\"}} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s CastingPermission.codec
