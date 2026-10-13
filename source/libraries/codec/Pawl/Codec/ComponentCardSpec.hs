module Pawl.Codec.ComponentCardSpec where

import qualified Pawl.Codec.ComponentCard as ComponentCard
import qualified Pawl.Codec.ProjectedCharacteristicsSpec as ProjectedCharacteristicsSpec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.CardIdentity as CardIdentity
import qualified Pawl.Types.ComponentCard as ComponentCard
import qualified Pawl.Types.PlayerId as PlayerId
import qualified Pawl.Types.PrintingId as PrintingId

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.ComponentCard" $ do
  Spec.it s "a bare printing" $
    Common.assertCodec
      s
      ComponentCard.codec
      ComponentCard.MkComponentCard
        { ComponentCard.printing = PrintingId.MkPrintingId 11,
          ComponentCard.identity = Nothing,
          ComponentCard.duplicate = Nothing
        }
      " {\"printing\":11} "
  -- CR 108.3 / 707.2: the card's identity, and the copiable values it was
  -- conjured with.
  Spec.it s "every key" $
    Common.assertCodec
      s
      ComponentCard.codec
      ComponentCard.MkComponentCard
        { ComponentCard.printing = PrintingId.MkPrintingId 17,
          ComponentCard.identity = Just (CardIdentity.MkCardIdentity 3 (PlayerId.MkPlayerId 2)),
          ComponentCard.duplicate = Just ProjectedCharacteristicsSpec.minimalCharacteristics
        }
      " {\"duplicate\":{\"names\":[\"Mountain\"],\"cardTypes\":[{\"type\":\"Land\"}]},\"identity\":{\"serial\":3,\"startingOwner\":2},\"printing\":17} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s ComponentCard.codec
