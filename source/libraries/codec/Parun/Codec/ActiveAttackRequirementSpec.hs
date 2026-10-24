module Parun.Codec.ActiveAttackRequirementSpec where

import qualified Parun.Codec.ActiveAttackRequirement as ActiveAttackRequirement
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ActiveAttackRequirement as ActiveAttackRequirement
import qualified Parun.Types.AttackTarget as AttackTarget
import qualified Parun.Types.Expiry as Expiry
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.RestrictedCreatures as RestrictedCreatures
import qualified Parun.Types.Timestamp as Timestamp

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ActiveAttackRequirement" $ do
  -- CR 508.1d, Alluring Siren's row. `source` and `attacker` are both ObjectIds
  -- and hold different ids, so the two cannot be swapped silently; CR 514.2's
  -- AtCleanup is what "this turn" arms.
  Spec.it s "a creature that must attack a player" $
    Common.assertCodec
      s
      ActiveAttackRequirement.codec
      ActiveAttackRequirement.MkActiveAttackRequirement
        { ActiveAttackRequirement.source = ObjectId.MkObjectId 1,
          ActiveAttackRequirement.controller = PlayerId.MkPlayerId 5,
          ActiveAttackRequirement.timestamp = Timestamp.MkTimestamp 2,
          ActiveAttackRequirement.expiry = Expiry.AtCleanup,
          ActiveAttackRequirement.attacker = RestrictedCreatures.Named (ObjectId.MkObjectId 3),
          ActiveAttackRequirement.defender = Just (AttackTarget.OfPlayer (PlayerId.MkPlayerId 4))
        }
      " {\"source\":1,\"controller\":5,\"timestamp\":2,\"expiry\":{\"type\":\"AtCleanup\"},\"attacker\":{\"type\":\"Named\",\"value\":3},\"defender\":{\"type\":\"OfPlayer\",\"value\":4}} "
  -- Courtly Provocateur's row: no defender, elided.
  Spec.it s "a creature that must attack anything" $
    Common.assertCodec
      s
      ActiveAttackRequirement.codec
      ActiveAttackRequirement.MkActiveAttackRequirement
        { ActiveAttackRequirement.source = ObjectId.MkObjectId 1,
          ActiveAttackRequirement.controller = PlayerId.MkPlayerId 5,
          ActiveAttackRequirement.timestamp = Timestamp.MkTimestamp 2,
          ActiveAttackRequirement.expiry = Expiry.AtCleanup,
          ActiveAttackRequirement.attacker = RestrictedCreatures.Named (ObjectId.MkObjectId 3),
          ActiveAttackRequirement.defender = Nothing
        }
      " {\"source\":1,\"controller\":5,\"timestamp\":2,\"expiry\":{\"type\":\"AtCleanup\"},\"attacker\":{\"type\":\"Named\",\"value\":3}} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s ActiveAttackRequirement.codec
