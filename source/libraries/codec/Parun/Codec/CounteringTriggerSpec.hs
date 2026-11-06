module Parun.Codec.CounteringTriggerSpec where

import qualified Parun.Codec.CounteringTrigger as CounteringTrigger
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CounteredKind as CounteredKind
import qualified Parun.Types.CounteringTrigger as CounteringTrigger
import qualified Parun.Types.PlayerRelation as PlayerRelation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CounteringTrigger" $ do
  Spec.it s "writes no key for the defaults" $
    Common.assertCodec s CounteringTrigger.codec CounteringTrigger.defaultValue " {} "
  -- Neither field at its default, so a dropped key fails to round-trip.
  Spec.it s "round-trips every field" $
    Common.assertCodec
      s
      CounteringTrigger.codec
      (CounteringTrigger.MkCounteringTrigger CounteredKind.Ability PlayerRelation.You)
      " {\"countered\":\"Ability\",\"counterer\":\"You\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s CounteringTrigger.codec
