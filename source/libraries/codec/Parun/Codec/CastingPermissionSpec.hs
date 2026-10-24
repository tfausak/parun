module Parun.Codec.CastingPermissionSpec where

import qualified Parun.Codec.CastingPermission as CastingPermission
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CastingPermission as CastingPermission
import qualified Parun.Types.KeywordFamily as KeywordFamily

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CastingPermission" $ do
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
