module Parun.Codec.CastingPermission where

import qualified Parun.Codec.Condition as Condition
import qualified Parun.Codec.KeywordFamily as KeywordFamily
import qualified Parun.Codec.ManaCost as ManaCost
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.CastingPermission as CastingPermission

codec :: Codec.Codec CastingPermission.CastingPermission
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "CastFromLibraryWhileSearching" CastingPermission.CastFromLibraryWhileSearching,
      Arm.optionalPayload "CastFromGraveyard" KeywordFamily.codec CastingPermission.CastFromGraveyard (\x -> case x of CastingPermission.CastFromGraveyard y -> Just y; _ -> Nothing),
      Arm.payload "CastAsThoughItHadFlash" flash (uncurry CastingPermission.CastAsThoughItHadFlash) (\x -> case x of CastingPermission.CastAsThoughItHadFlash c m -> Just (c, m); _ -> Nothing)
    ]
  where
    flash =
      Fields.object $
        (,)
          <$> Fields.defaulted "condition" Nothing (Common.maybe Condition.codec) fst
          <*> Fields.defaulted "additionalCost" Nothing (Common.maybe ManaCost.codec) snd

tagOf :: CastingPermission.CastingPermission -> String
tagOf x = case x of
  CastingPermission.CastFromLibraryWhileSearching {} -> "CastFromLibraryWhileSearching"
  CastingPermission.CastFromGraveyard {} -> "CastFromGraveyard"
  CastingPermission.CastAsThoughItHadFlash {} -> "CastAsThoughItHadFlash"
