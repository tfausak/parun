module Parun.Codec.DrawRewriteSpec where

import qualified Data.Sequence as Seq
import qualified Data.Text as Text
import qualified Parun.Codec.DrawRewrite as DrawRewrite
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.DrawRewrite as DrawRewrite
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.FromOutsideTheGame as FromOutsideTheGame
import qualified Parun.Types.OutsideDestination as OutsideDestination
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.DrawRewrite" $ do
  -- CR 614.1a: Words of Worship.
  Spec.it s "GainLife" $
    Common.assertCodec
      s
      (DrawRewrite.codec Common.natural)
      (DrawRewrite.GainLife 5)
      " {\"type\":\"GainLife\",\"value\":5} "
  -- CR 400.11c: Ring of Ma'rûf, whose sentence states no quality and prints no
  -- reveal.
  Spec.it s "FromOutsideTheGame" $
    Common.assertCodec
      s
      (DrawRewrite.codec Common.natural)
      ( DrawRewrite.FromOutsideTheGame
          FromOutsideTheGame.MkFromOutsideTheGame
            { FromOutsideTheGame.count = 1,
              FromOutsideTheGame.upTo = False,
              FromOutsideTheGame.destination = OutsideDestination.Hand,
              FromOutsideTheGame.filter = Filter.And [],
              FromOutsideTheGame.reveal = False
            }
      )
      " {\"type\":\"FromOutsideTheGame\",\"value\":{\"count\":1,\"destination\":{\"type\":\"Hand\"},\"filter\":{\"type\":\"And\",\"value\":[]},\"reveal\":false,\"upTo\":false}} "
  -- CR 702.52a: Darkblast's dredge 3.
  Spec.it s "Dredge" $
    Common.assertCodec
      s
      (DrawRewrite.codec Common.natural)
      (DrawRewrite.Dredge 3)
      " {\"type\":\"Dredge\",\"value\":3} "
  -- CR 614.10: Plagiarize.
  Spec.it s "YouDraw" $
    Common.assertCodec
      s
      (DrawRewrite.codec Common.natural)
      DrawRewrite.YouDraw
      " {\"type\":\"YouDraw\"} "
  -- CR 614.6: Zur's Weirding.
  Spec.it s "OthersMayPayLife" $
    Common.assertCodec
      s
      (DrawRewrite.codec Common.natural)
      (DrawRewrite.OthersMayPayLife 2)
      " {\"type\":\"OthersMayPayLife\",\"value\":2} "
  -- CR 614.6 / 104.3e: Forbidden Crypt.
  Spec.it s "FromGraveyardOrLose" $
    Common.assertCodec
      s
      (DrawRewrite.codec Common.natural)
      DrawRewrite.FromGraveyardOrLose
      " {\"type\":\"FromGraveyardOrLose\"} "
  -- CR 614.1a / 701.20a: Abundance.
  Spec.it s "RevealUntilChosenKind" $
    Common.assertCodec
      s
      (DrawRewrite.codec Common.natural)
      DrawRewrite.RevealUntilChosenKind
      " {\"type\":\"RevealUntilChosenKind\"} "
  -- CR 614.1a / 614.5: Alhammarret's Archive.
  Spec.it s "DrawInstead" $
    Common.assertCodec
      s
      (DrawRewrite.codec Common.natural)
      (DrawRewrite.DrawInstead 2)
      " {\"type\":\"DrawInstead\",\"value\":2} "
  -- CR 614.1a / 701.9a / 701.17a: Chains of Mephistopheles.
  Spec.it s "DiscardThenDrawOrMill" $
    Common.assertCodec
      s
      (DrawRewrite.codec Common.natural)
      DrawRewrite.DiscardThenDrawOrMill
      " {\"type\":\"DiscardThenDrawOrMill\"} "
  -- CR 614.1a / 701.20e: Aladdin's Lamp.
  Spec.it s "KeepOneOfTopThenDraw" $
    Common.assertCodec
      s
      (DrawRewrite.codec Common.natural)
      (DrawRewrite.KeepOneOfTopThenDraw (Quantity.InSlot (SlotName.MkSlotName (Text.pack "X"))))
      " {\"type\":\"KeepOneOfTopThenDraw\",\"value\":{\"type\":\"InSlot\",\"value\":\"X\"}} "
  -- CR 614.10: Island Sanctuary.
  Spec.it s "MaySkipFor" $
    Common.assertCodec
      s
      (DrawRewrite.codec Common.natural)
      (DrawRewrite.MaySkipFor (Seq.fromList [7]))
      " {\"type\":\"MaySkipFor\",\"value\":[7]} "
  Spec.it s "has a schema" $ Common.assertHasSchema s (DrawRewrite.codec Common.natural)
