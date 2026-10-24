module Parun.Codec.ActiveObjectProhibitionSpec where

import qualified Parun.Codec.ActiveObjectProhibition as ActiveObjectProhibition
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ActiveObjectProhibition as ActiveObjectProhibition
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Expiry as Expiry
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.Prohibition as Prohibition
import qualified Parun.Types.RestrictedCreatures as RestrictedCreatures
import qualified Parun.Types.Timestamp as Timestamp

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ActiveObjectProhibition" $ do
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
