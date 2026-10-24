module Parun.Codec.TakingSpec where

import qualified Data.Sequence as Seq
import qualified Data.Text as Text
import qualified Parun.Codec.Taking as Taking
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Choices as Choices.Type
import qualified Parun.Types.Label as Label.Type
import qualified Parun.Types.Reference as Reference.Type
import qualified Parun.Types.Taking as Taking.Type

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Taking" $ do
  Spec.it s "its choices share its action" $
    Common.assertCodec
      s
      Taking.codec
      Taking.Type.MkTaking
        { Taking.Type.action = Text.pack "TurnFaceUp $piker Manifest",
          Taking.Type.choices = Choices.Type.none {Choices.Type.manaSources = Seq.singleton (Just (Reference.Type.Labelled (Label.Type.MkLabel (Text.pack "mountain"))))}
        }
      " {\"action\":\"TurnFaceUp $piker Manifest\",\"mana\":[\"$mountain\"]} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s Taking.codec
