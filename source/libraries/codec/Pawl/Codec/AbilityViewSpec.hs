module Pawl.Codec.AbilityViewSpec where

import qualified Pawl.Codec.AbilityView as AbilityView
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.AbilityView as AbilityView
import qualified Pawl.Types.ObjectId as ObjectId

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.AbilityView" $ do
  Spec.it s "a known source" $
    Common.assertCodec s AbilityView.codec (AbilityView.MkAbilityView (Just (ObjectId.MkObjectId 5))) "{\"source\":5}"
  Spec.it s "an unknown source" $
    Common.assertCodec s AbilityView.codec (AbilityView.MkAbilityView Nothing) "{\"source\":null}"
  Spec.it s "has a schema" $ Common.assertHasSchema s AbilityView.codec
