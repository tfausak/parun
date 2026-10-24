module Parun.Codec.ComponentCardSpec where

import qualified Parun.Codec.ComponentCard as ComponentCard
import qualified Parun.Codec.ProjectedCharacteristicsSpec as ProjectedCharacteristicsSpec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardIdentity as CardIdentity
import qualified Parun.Types.ComponentCard as ComponentCard
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.PrintingId as PrintingId

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ComponentCard" $ do
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
