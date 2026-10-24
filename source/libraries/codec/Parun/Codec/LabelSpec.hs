module Parun.Codec.LabelSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.Label as Label
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Label as Label.Type

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Label" $ do
  Spec.it s "a label is a bare string" $
    Common.assertCodec s Label.codec (Label.Type.MkLabel (Text.pack "bear")) " \"bear\" "
  Spec.it s "has a schema" $
    Common.assertHasSchema s Label.codec
