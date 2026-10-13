module Pawl.Codec.MergeComponentSpec where

import qualified Data.List.NonEmpty as NonEmpty
import qualified Pawl.Codec.MergeComponent as MergeComponent
import qualified Pawl.Codec.ProjectedCharacteristicsSpec as ProjectedCharacteristicsSpec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.CardIdentity as CardIdentity
import qualified Pawl.Types.ComponentCard as ComponentCard
import qualified Pawl.Types.MeldSource as MeldSource
import qualified Pawl.Types.MergeComponent as MergeComponent
import qualified Pawl.Types.PlayerId as PlayerId
import qualified Pawl.Types.PrintingId as PrintingId

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.MergeComponent" $ do
  -- CR 108.2.
  Spec.it s "OfCard" $
    Common.assertCodec
      s
      MergeComponent.codec
      (MergeComponent.OfCard (ComponentCard.MkComponentCard (PrintingId.MkPrintingId 11) Nothing Nothing))
      " {\"type\":\"OfCard\",\"value\":{\"printing\":11}} "
  -- CR 108.3 / 707.2: a card component with its identity and the values it was
  -- conjured with.
  Spec.it s "OfCard, a conjured duplicate with an identity" $
    Common.assertCodec
      s
      MergeComponent.codec
      (MergeComponent.OfCard (ComponentCard.MkComponentCard (PrintingId.MkPrintingId 18) (Just (CardIdentity.MkCardIdentity 4 (PlayerId.MkPlayerId 1))) (Just ProjectedCharacteristicsSpec.minimalCharacteristics)))
      " {\"type\":\"OfCard\",\"value\":{\"printing\":18,\"identity\":{\"serial\":4,\"startingOwner\":1},\"duplicate\":{\"names\":[\"Mountain\"],\"cardTypes\":[{\"type\":\"Land\"}]}}} "
  -- CR 111.3 / 730.2d: a DIFFERENT tag on the same payload shape, which is the
  -- whole of what rule 730.2d asks of a component.
  Spec.it s "OfToken" $
    Common.assertCodec
      s
      MergeComponent.codec
      (MergeComponent.OfToken (PrintingId.MkPrintingId 12))
      " {\"type\":\"OfToken\",\"value\":12} "
  -- CR 701.42a / 712.8g: the arm whose payload is not a printing at all -- the
  -- combined back face beside the two cards representing the component.
  Spec.it s "OfMeld" $
    Common.assertCodec
      s
      MergeComponent.codec
      (MergeComponent.OfMeld MeldSource.MkMeldSource {MeldSource.result = PrintingId.MkPrintingId 13, MeldSource.components = ComponentCard.MkComponentCard (PrintingId.MkPrintingId 14) Nothing Nothing NonEmpty.:| [ComponentCard.MkComponentCard (PrintingId.MkPrintingId 15) Nothing Nothing]})
      " {\"type\":\"OfMeld\",\"value\":{\"components\":[{\"printing\":14},{\"printing\":15}],\"result\":13}} "
  -- CR 730.2's "or copy": the third tag over the printing payload, which is what
  -- separates it from the two above.
  Spec.it s "OfSpellCopy" $
    Common.assertCodec
      s
      MergeComponent.codec
      (MergeComponent.OfSpellCopy (PrintingId.MkPrintingId 16))
      " {\"type\":\"OfSpellCopy\",\"value\":16} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s MergeComponent.codec
