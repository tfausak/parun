module Parun.Codec.ActivationSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.Activation as Activation
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Activation as Activation.Type
import qualified Parun.Types.Choices as Choices.Type
import qualified Parun.Types.Label as Label.Type
import qualified Parun.Types.Reference as Reference.Type

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Activation" $ do
  Spec.it s "an ability index beside its choices" $
    Common.assertCodec
      s
      Activation.codec
      Activation.Type.MkActivation
        { Activation.Type.object = Reference.Type.Labelled (Label.Type.MkLabel (Text.pack "stone")),
          Activation.Type.ability = Just 1,
          Activation.Type.choices = Choices.Type.none {Choices.Type.x = Just 2}
        }
      " {\"object\":\"$stone\",\"ability\":1,\"x\":2} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s Activation.codec
