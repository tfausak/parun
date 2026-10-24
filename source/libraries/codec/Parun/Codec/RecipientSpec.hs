module Parun.Codec.RecipientSpec where

import qualified Parun.Codec.Recipient as Recipient
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.Pile as Pile
import qualified Parun.Types.PileDraw as PileDraw
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.Recipient as Recipient
import qualified Parun.Types.Timestamp as Timestamp

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Recipient" $ do
  Spec.it s "ToCreature" $
    Common.assertCodec
      s
      Recipient.codec
      (Recipient.ToCreature (ObjectId.MkObjectId 1))
      " {\"type\":\"ToCreature\",\"value\":1} "
  -- CR 120.3c's recipient tag is a different arm of Recipient from ToObject
  -- (see Parun.Types.Recipient's comment on it), so it gets its own case.
  Spec.it s "ToPlaneswalker" $
    Common.assertCodec
      s
      Recipient.codec
      (Recipient.ToPlaneswalker (ObjectId.MkObjectId 2))
      " {\"type\":\"ToPlaneswalker\",\"value\":2} "
  -- CR 120.3h's is a third, for CR 115.4's fourth kind of "any target".
  Spec.it s "ToBattle" $
    Common.assertCodec
      s
      Recipient.codec
      (Recipient.ToBattle (ObjectId.MkObjectId 5))
      " {\"type\":\"ToBattle\",\"value\":5} "
  Spec.it s "ToPlayer" $
    Common.assertCodec
      s
      Recipient.codec
      (Recipient.ToPlayer (PlayerId.MkPlayerId 3))
      " {\"type\":\"ToPlayer\",\"value\":3} "
  Spec.it s "ToObject" $
    Common.assertCodec
      s
      Recipient.codec
      (Recipient.ToObject (ObjectId.MkObjectId 4))
      " {\"type\":\"ToObject\",\"value\":4} "
  -- CR 406.4's pile, the one arm naming neither an object nor a player.
  Spec.it s "ToPile" $
    Common.assertCodec
      s
      Recipient.codec
      (Recipient.ToPile (PileDraw.MkPileDraw {PileDraw.pile = Pile.OfFaceDown (Timestamp.MkTimestamp 6), PileDraw.ordinal = 1}))
      " {\"type\":\"ToPile\",\"value\":{\"ordinal\":1,\"pile\":{\"type\":\"OfFaceDown\",\"value\":6}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s Recipient.codec
