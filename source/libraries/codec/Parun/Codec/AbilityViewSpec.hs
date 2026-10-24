module Parun.Codec.AbilityViewSpec where

import qualified Parun.Codec.AbilityView as AbilityView
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AbilityView as AbilityView
import qualified Parun.Types.ObjectId as ObjectId

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AbilityView" $ do
  Spec.it s "a known source" $
    Common.assertCodec s AbilityView.codec (AbilityView.MkAbilityView (Just (ObjectId.MkObjectId 5))) "{\"source\":5}"
  Spec.it s "an unknown source" $
    Common.assertCodec s AbilityView.codec (AbilityView.MkAbilityView Nothing) "{\"source\":null}"
  Spec.it s "has a schema" $ Common.assertHasSchema s AbilityView.codec
