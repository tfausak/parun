module Parun.Codec.CastingSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.Casting as Casting
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Casting as Casting.Type
import qualified Parun.Types.Choices as Choices.Type
import qualified Parun.Types.Label as Label.Type
import qualified Parun.Types.Reference as Reference.Type

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Casting" $ do
  Spec.it s "its choices share its object" $
    Common.assertCodec
      s
      Casting.codec
      Casting.Type.MkCasting
        { Casting.Type.object = Reference.Type.Labelled (Label.Type.MkLabel (Text.pack "bolt")),
          Casting.Type.choices = Choices.Type.none {Choices.Type.targets = Just [Reference.Type.Labelled (Label.Type.MkLabel (Text.pack "bob"))]},
          Casting.Type.faceDown = Nothing
        }
      " {\"object\":\"$bolt\",\"targets\":[\"$bob\"]} "
  -- A morph card in hand offers two casts (CR 702.37c); the face-up one is named.
  Spec.it s "it may say whether the spell is cast face down" $
    Common.assertCodec
      s
      Casting.codec
      Casting.Type.MkCasting
        { Casting.Type.object = Reference.Type.Labelled (Label.Type.MkLabel (Text.pack "vesuvan")),
          Casting.Type.choices = Choices.Type.none,
          Casting.Type.faceDown = Just False
        }
      " {\"object\":\"$vesuvan\",\"faceDown\":false} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s Casting.codec
