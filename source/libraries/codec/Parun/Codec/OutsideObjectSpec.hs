module Parun.Codec.OutsideObjectSpec where

import qualified Data.List.NonEmpty as NonEmpty
import qualified Parun.Codec.OutsideObject as OutsideObject
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardIdentity as CardIdentity
import qualified Parun.Types.ComponentCard as ComponentCard
import qualified Parun.Types.FaceDownReason as FaceDownReason
import qualified Parun.Types.Facing as Facing
import qualified Parun.Types.OutsideObject as OutsideObject
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.PrintingId as PrintingId

codec :: Codec.Codec OutsideObject.OutsideObject
codec = OutsideObject.codec

card :: PrintingId.PrintingId -> Maybe CardIdentity.CardIdentity -> ComponentCard.ComponentCard
card printing identity = ComponentCard.MkComponentCard printing identity Nothing

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.OutsideObject" $ do
  -- CR 108.3b's owner, plus which printing the outer frame's card is. The
  -- default facing is elided, as Parun.Codec.Object's own field is.
  Spec.it s "MkOutsideObject" $
    Common.assertCodec
      s
      codec
      ( OutsideObject.MkOutsideObject
          { OutsideObject.owner = PlayerId.MkPlayerId 0,
            OutsideObject.printing = PrintingId.MkPrintingId 1,
            OutsideObject.facing = Facing.FaceUp,
            OutsideObject.cards = card (PrintingId.MkPrintingId 1) Nothing NonEmpty.:| []
          }
      )
      " {\"owner\":0,\"printing\":1,\"cards\":[{\"printing\":1}]} "
  -- CR 708.2's status, the one thing carried besides the printing.
  Spec.it s "MkOutsideObject face down" $
    Common.assertCodec
      s
      codec
      ( OutsideObject.MkOutsideObject
          { OutsideObject.owner = PlayerId.MkPlayerId 0,
            OutsideObject.printing = PrintingId.MkPrintingId 1,
            OutsideObject.facing = Facing.faceDown FaceDownReason.Manifested,
            OutsideObject.cards = card (PrintingId.MkPrintingId 1) Nothing NonEmpty.:| []
          }
      )
      " {\"owner\":0,\"printing\":1,\"facing\":{\"type\":\"FaceDown\",\"value\":{\"reason\":{\"type\":\"Manifested\"},\"listed\":{}}},\"cards\":[{\"printing\":1}]} "
  -- CR 712.21 / 712.8g: a melded permanent, offered by its combined face and
  -- bringing both cards.
  Spec.it s "MkOutsideObject melded" $
    Common.assertCodec
      s
      codec
      ( OutsideObject.MkOutsideObject
          { OutsideObject.owner = PlayerId.MkPlayerId 0,
            OutsideObject.printing = PrintingId.MkPrintingId 3,
            OutsideObject.facing = Facing.FaceUp,
            OutsideObject.cards = card (PrintingId.MkPrintingId 1) (Just (CardIdentity.MkCardIdentity 5 (PlayerId.MkPlayerId 4))) NonEmpty.:| [card (PrintingId.MkPrintingId 2) (Just (CardIdentity.MkCardIdentity 6 (PlayerId.MkPlayerId 7)))]
          }
      )
      " {\"owner\":0,\"printing\":3,\"cards\":[{\"printing\":1,\"identity\":{\"serial\":5,\"startingOwner\":4}},{\"printing\":2,\"identity\":{\"serial\":6,\"startingOwner\":7}}]} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
