module Parun.Codec.WhenSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.When as When
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.EndingStep as EndingStep.Type
import qualified Parun.Types.Label as Label.Type
import qualified Parun.Types.Phase as Phase.Type
import qualified Parun.Types.When as When.Type

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.When" $ do
  Spec.it s "a turn, a flat step and a player" $
    Common.assertCodec s When.codec (When.Type.MkWhen 2 (Phase.Type.Ending EndingStep.Type.EndStep) (Label.Type.MkLabel (Text.pack "bob"))) " {\"turn\":2,\"step\":\"EndStep\",\"player\":\"bob\"} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s When.codec
