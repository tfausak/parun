module Parun.Codec.CastingSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.Casting as Casting
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardName as CardName.Type
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
          Casting.Type.faceDown = Nothing,
          Casting.Type.face = Nothing
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
          Casting.Type.faceDown = Just False,
          Casting.Type.face = Nothing
        }
      " {\"object\":\"$vesuvan\",\"faceDown\":false} "
  -- A split card offers a cast of each half (CR 709.3); the half is named.
  Spec.it s "it may name the half of a split card cast" $
    Common.assertCodec
      s
      Casting.codec
      Casting.Type.MkCasting
        { Casting.Type.object = Reference.Type.Labelled (Label.Type.MkLabel (Text.pack "consume")),
          Casting.Type.choices = Choices.Type.none,
          Casting.Type.faceDown = Nothing,
          Casting.Type.face = Just (CardName.Type.MkCardName (Text.pack "Consume"))
        }
      " {\"object\":\"$consume\",\"face\":\"Consume\"} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s Casting.codec
