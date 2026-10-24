module Parun.Codec.DamageIsSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.DamageIs as DamageIs
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.DamageIs as DamageIs.Type
import qualified Parun.Types.Label as Label.Type
import qualified Parun.Types.Reference as Reference.Type

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.DamageIs" $ do
  Spec.it s "an object and its damage" $
    Common.assertCodec s DamageIs.codec (DamageIs.Type.MkDamageIs (Reference.Type.Labelled (Label.Type.MkLabel (Text.pack "wall"))) 2) " {\"object\":\"$wall\",\"damage\":2} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s DamageIs.codec
