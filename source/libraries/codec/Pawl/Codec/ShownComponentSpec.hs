module Pawl.Codec.ShownComponentSpec where

import qualified Data.Text as Text
import qualified Pawl.Codec.ShownComponent as ShownComponent
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.CardName as CardName
import qualified Pawl.Types.ComponentCard as ComponentCard
import qualified Pawl.Types.MergeComponent as MergeComponent
import qualified Pawl.Types.PrintingId as PrintingId
import qualified Pawl.Types.ShownComponent as ShownComponent

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.ShownComponent" $ do
  -- CR 712.8d: a component showing its front face omits the face.
  Spec.it s "front face up" $
    Common.assertCodec
      s
      ShownComponent.codec
      (ShownComponent.MkShownComponent (MergeComponent.OfCard (ComponentCard.MkComponentCard (PrintingId.MkPrintingId 11) Nothing Nothing)) Nothing)
      " {\"component\":{\"type\":\"OfCard\",\"value\":{\"printing\":11}}} "
  -- CR 730.2i: a double-faced component showing its back face.
  Spec.it s "back face up" $
    Common.assertCodec
      s
      ShownComponent.codec
      (ShownComponent.MkShownComponent (MergeComponent.OfCard (ComponentCard.MkComponentCard (PrintingId.MkPrintingId 11) Nothing Nothing)) (Just (CardName.MkCardName (Text.pack "Synthetic Graftbeast"))))
      " {\"component\":{\"type\":\"OfCard\",\"value\":{\"printing\":11}},\"face\":\"Synthetic Graftbeast\"} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s ShownComponent.codec
