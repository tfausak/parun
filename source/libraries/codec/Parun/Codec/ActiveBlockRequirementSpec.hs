module Parun.Codec.ActiveBlockRequirementSpec where

import qualified Parun.Codec.ActiveBlockRequirement as ActiveBlockRequirement
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ActiveBlockRequirement as ActiveBlockRequirement
import qualified Parun.Types.Expiry as Expiry
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PhaseSelector as PhaseSelector
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.RequirementArity as RequirementArity
import qualified Parun.Types.RestrictedCreatures as RestrictedCreatures
import qualified Parun.Types.Timestamp as Timestamp

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ActiveBlockRequirement" $ do
  -- CR 509.1c, provoke's row (CR 702.39a). All four ids differ, so no two
  -- of them can be swapped silently, and provoke's "this combat" arms the phase
  -- expiry rather than CR 514.2's cleanup.
  Spec.it s "a creature that must block an attacker" $
    Common.assertCodec
      s
      ActiveBlockRequirement.codec
      ActiveBlockRequirement.MkActiveBlockRequirement
        { ActiveBlockRequirement.source = ObjectId.MkObjectId 1,
          ActiveBlockRequirement.controller = PlayerId.MkPlayerId 5,
          ActiveBlockRequirement.timestamp = Timestamp.MkTimestamp 2,
          ActiveBlockRequirement.expiry = Expiry.AtEndOf PhaseSelector.CombatPhase,
          ActiveBlockRequirement.blocker = RestrictedCreatures.Named (ObjectId.MkObjectId 3),
          ActiveBlockRequirement.attacker = Just (RestrictedCreatures.Named (ObjectId.MkObjectId 4)),
          ActiveBlockRequirement.arity = RequirementArity.EachSubject
        }
      " {\"source\":1,\"controller\":5,\"timestamp\":2,\"expiry\":{\"type\":\"AtEndOf\",\"value\":{\"type\":\"CombatPhase\"}},\"blocker\":{\"type\":\"Named\",\"value\":3},\"attacker\":{\"type\":\"Named\",\"value\":4},\"arity\":{\"type\":\"EachSubject\"}} "
  -- No attacker named, one requirement per attacker any blocker obeys.
  Spec.it s "a requirement naming no attacker" $
    Common.assertCodec
      s
      ActiveBlockRequirement.codec
      ActiveBlockRequirement.MkActiveBlockRequirement
        { ActiveBlockRequirement.source = ObjectId.MkObjectId 1,
          ActiveBlockRequirement.controller = PlayerId.MkPlayerId 5,
          ActiveBlockRequirement.timestamp = Timestamp.MkTimestamp 2,
          ActiveBlockRequirement.expiry = Expiry.AtEndOf PhaseSelector.CombatPhase,
          ActiveBlockRequirement.blocker = RestrictedCreatures.Named (ObjectId.MkObjectId 3),
          ActiveBlockRequirement.attacker = Nothing,
          ActiveBlockRequirement.arity = RequirementArity.AnySubject
        }
      " {\"source\":1,\"controller\":5,\"timestamp\":2,\"expiry\":{\"type\":\"AtEndOf\",\"value\":{\"type\":\"CombatPhase\"}},\"blocker\":{\"type\":\"Named\",\"value\":3},\"attacker\":null,\"arity\":{\"type\":\"AnySubject\"}} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s ActiveBlockRequirement.codec
