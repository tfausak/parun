module Pawl.Codec.ActiveObjectProhibitionSpec where

import qualified Pawl.Codec.ActiveObjectProhibition as ActiveObjectProhibition
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.ActiveObjectProhibition as ActiveObjectProhibition
import qualified Pawl.Types.CardType as CardType
import qualified Pawl.Types.Expiry as Expiry
import qualified Pawl.Types.Filter as Filter
import qualified Pawl.Types.ObjectId as ObjectId
import qualified Pawl.Types.PlayerId as PlayerId
import qualified Pawl.Types.Prohibition as Prohibition
import qualified Pawl.Types.RestrictedCreatures as RestrictedCreatures
import qualified Pawl.Types.Timestamp as Timestamp

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.ActiveObjectProhibition" $ do
  -- CR 602.5. `source` and the named id are both ObjectIds and differ, so a
  -- swap cannot pass.
  Spec.it s "a permanent whose abilities can't be activated" $
    Common.assertCodec
      s
      ActiveObjectProhibition.codec
      ActiveObjectProhibition.MkActiveObjectProhibition
        { ActiveObjectProhibition.source = ObjectId.MkObjectId 1,
          ActiveObjectProhibition.controller = PlayerId.MkPlayerId 4,
          ActiveObjectProhibition.timestamp = Timestamp.MkTimestamp 2,
          ActiveObjectProhibition.expiry = Expiry.AtCleanup,
          ActiveObjectProhibition.what = Prohibition.Activate,
          ActiveObjectProhibition.affected = RestrictedCreatures.Named (ObjectId.MkObjectId 3)
        }
      " {\"source\":1,\"controller\":4,\"timestamp\":2,\"expiry\":{\"type\":\"AtCleanup\"},\"what\":{\"type\":\"Activate\"},\"affected\":{\"type\":\"Named\",\"value\":3}} "
  -- CR 611.2c: a class, inert until that player's untap step (Exhaustion).
  Spec.it s "a class that doesn't untap during a player's untap step" $
    Common.assertCodec
      s
      ActiveObjectProhibition.codec
      ActiveObjectProhibition.MkActiveObjectProhibition
        { ActiveObjectProhibition.source = ObjectId.MkObjectId 1,
          ActiveObjectProhibition.controller = PlayerId.MkPlayerId 4,
          ActiveObjectProhibition.timestamp = Timestamp.MkTimestamp 2,
          ActiveObjectProhibition.expiry = Expiry.DuringUntapStepOf (PlayerId.MkPlayerId 5),
          ActiveObjectProhibition.what = Prohibition.Untap,
          ActiveObjectProhibition.affected = RestrictedCreatures.Matching (Filter.HasCardType CardType.Creature)
        }
      " {\"source\":1,\"controller\":4,\"timestamp\":2,\"expiry\":{\"type\":\"DuringUntapStepOf\",\"value\":5},\"what\":{\"type\":\"Untap\"},\"affected\":{\"type\":\"Matching\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}}} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s ActiveObjectProhibition.codec
