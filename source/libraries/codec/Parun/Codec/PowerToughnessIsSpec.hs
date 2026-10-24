module Parun.Codec.PowerToughnessIsSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.PowerToughnessIs as PowerToughnessIs
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Label as Label.Type
import qualified Parun.Types.PowerToughnessIs as PowerToughnessIs.Type
import qualified Parun.Types.Reference as Reference.Type

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PowerToughnessIs" $ do
  Spec.it s "an object and its power and toughness" $
    Common.assertCodec s PowerToughnessIs.codec (PowerToughnessIs.Type.MkPowerToughnessIs (Reference.Type.Labelled (Label.Type.MkLabel (Text.pack "bear"))) 2 (-1)) " {\"object\":\"$bear\",\"power\":2,\"toughness\":-1} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s PowerToughnessIs.codec
