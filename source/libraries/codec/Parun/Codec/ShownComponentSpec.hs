module Parun.Codec.ShownComponentSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.ShownComponent as ShownComponent
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardName as CardName
import qualified Parun.Types.ComponentCard as ComponentCard
import qualified Parun.Types.FaceDownReason as FaceDownReason
import qualified Parun.Types.Facing as Facing
import qualified Parun.Types.MergeComponent as MergeComponent
import qualified Parun.Types.PrintingId as PrintingId
import qualified Parun.Types.ShownComponent as ShownComponent

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ShownComponent" $ do
  -- CR 712.8d: a component showing its front face omits the face.
  Spec.it s "front face up" $
    Common.assertCodec
      s
      ShownComponent.codec
      (ShownComponent.MkShownComponent (MergeComponent.OfCard (ComponentCard.MkComponentCard (PrintingId.MkPrintingId 11) Nothing Nothing)) Nothing Facing.FaceUp)
      " {\"component\":{\"type\":\"OfCard\",\"value\":{\"printing\":11}}} "
  -- CR 730.2i: a double-faced component showing its back face.
  Spec.it s "back face up" $
    Common.assertCodec
      s
      ShownComponent.codec
      (ShownComponent.MkShownComponent (MergeComponent.OfCard (ComponentCard.MkComponentCard (PrintingId.MkPrintingId 11) Nothing Nothing)) (Just (CardName.MkCardName (Text.pack "Synthetic Graftbeast"))) Facing.FaceUp)
      " {\"component\":{\"type\":\"OfCard\",\"value\":{\"printing\":11}},\"face\":\"Synthetic Graftbeast\"} "
  -- CR 730.2e: a face-down component under a face-up topmost one.
  Spec.it s "face down" $
    Common.assertCodec
      s
      ShownComponent.codec
      (ShownComponent.MkShownComponent (MergeComponent.OfCard (ComponentCard.MkComponentCard (PrintingId.MkPrintingId 11) Nothing Nothing)) Nothing (Facing.faceDown FaceDownReason.Morphed))
      " {\"component\":{\"type\":\"OfCard\",\"value\":{\"printing\":11}},\"facing\":{\"type\":\"FaceDown\",\"value\":{\"reason\":{\"type\":\"Morphed\"},\"listed\":{}}}} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s ShownComponent.codec
