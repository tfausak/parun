module Parun.Codec.CastingPermissionSpec where

import qualified Parun.Codec.CastingPermission as CastingPermission
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CastingPermission as CastingPermission
import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.CostAmount as CostAmount
import qualified Parun.Types.CostComponent as CostComponent
import qualified Parun.Types.KeywordFamily as KeywordFamily
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaSymbol as ManaSymbol

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
      (CastingPermission.CastFromGraveyard Nothing [])
      " {\"type\":\"CastFromGraveyard\",\"value\":{}} "
  Spec.it s "CastFromGraveyard using a keyword" $
    Common.assertCodec
      s
      CastingPermission.codec
      (CastingPermission.CastFromGraveyard (Just KeywordFamily.Blitz) [])
      " {\"type\":\"CastFromGraveyard\",\"value\":{\"using\":{\"type\":\"Blitz\"}}} "
  Spec.it s "CastFromGraveyard paying an additional cost" $
    Common.assertCodec
      s
      CastingPermission.codec
      (CastingPermission.CastFromGraveyard Nothing [CostComponent.PayLife (CostAmount.Fixed 2)])
      " {\"type\":\"CastFromGraveyard\",\"value\":{\"additionalCosts\":[{\"type\":\"PayLife\",\"value\":{\"type\":\"Fixed\",\"value\":2}}]}} "
  Spec.it s "PlayFromGraveyard" $
    Common.assertCodec
      s
      CastingPermission.codec
      CastingPermission.PlayFromGraveyard
      " {\"type\":\"PlayFromGraveyard\"} "
  Spec.it s "CastAsThoughItHadFlash unconditioned and free" $
    Common.assertCodec
      s
      CastingPermission.codec
      (CastingPermission.CastAsThoughItHadFlash Nothing Nothing)
      " {\"type\":\"CastAsThoughItHadFlash\",\"value\":{}} "
  Spec.it s "CastAsThoughItHadFlash under a condition for an additional cost" $
    Common.assertCodec
      s
      CastingPermission.codec
      (CastingPermission.CastAsThoughItHadFlash (Just (Condition.Any [])) (Just (ManaCost.MkManaCost [ManaSymbol.Generic 2])))
      " {\"type\":\"CastAsThoughItHadFlash\",\"value\":{\"condition\":{\"type\":\"Any\",\"value\":[]},\"additionalCost\":[{\"type\":\"Generic\",\"value\":2}]}} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s CastingPermission.codec
