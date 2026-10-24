module Parun.Codec.ActiveAttackProhibitionSpec where

import qualified Data.Set as Set
import qualified Parun.Codec.ActiveAttackProhibition as ActiveAttackProhibition
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ActiveAttackProhibition as ActiveAttackProhibition
import qualified Parun.Types.AimedAt as AimedAt
import qualified Parun.Types.AimedPlayers as AimedPlayers
import qualified Parun.Types.AttackTargetKind as AttackTargetKind
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Expiry as Expiry
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.PlayerScope as PlayerScope
import qualified Parun.Types.RestrictedCreatures as RestrictedCreatures
import qualified Parun.Types.Timestamp as Timestamp

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ActiveAttackProhibition" $ do
  -- CR 508.1c, Netter en-Dal's row. `source` and the named id are both
  -- ObjectIds and differ, so a swap cannot pass; "this turn" arms CR 514.2's
  -- AtCleanup.
  Spec.it s "a permanent that can't attack this turn" $
    Common.assertCodec
      s
      ActiveAttackProhibition.codec
      ActiveAttackProhibition.MkActiveAttackProhibition
        { ActiveAttackProhibition.source = ObjectId.MkObjectId 1,
          ActiveAttackProhibition.controller = PlayerId.MkPlayerId 4,
          ActiveAttackProhibition.timestamp = Timestamp.MkTimestamp 2,
          ActiveAttackProhibition.expiry = Expiry.AtCleanup,
          ActiveAttackProhibition.affected = RestrictedCreatures.Named (ObjectId.MkObjectId 3),
          ActiveAttackProhibition.aimedAt = Nothing
        }
      " {\"source\":1,\"controller\":4,\"timestamp\":2,\"expiry\":{\"type\":\"AtCleanup\"},\"affected\":{\"type\":\"Named\",\"value\":3}} "
  -- CR 611.2c / 802.3a, Chronomantic Escape's row: a class, aimed at the
  -- controller's seat, until their next turn.
  Spec.it s "a class that can't attack a player until their next turn" $
    Common.assertCodec
      s
      ActiveAttackProhibition.codec
      ActiveAttackProhibition.MkActiveAttackProhibition
        { ActiveAttackProhibition.source = ObjectId.MkObjectId 1,
          ActiveAttackProhibition.controller = PlayerId.MkPlayerId 4,
          ActiveAttackProhibition.timestamp = Timestamp.MkTimestamp 2,
          ActiveAttackProhibition.expiry = Expiry.AtTurnOf (PlayerId.MkPlayerId 4),
          ActiveAttackProhibition.affected = RestrictedCreatures.Matching (Filter.HasCardType CardType.Creature),
          ActiveAttackProhibition.aimedAt = Just (AimedAt.MkAimedAt (AimedPlayers.Scoped (PlayerScope.Related PlayerRelation.You)) (Set.singleton AttackTargetKind.OfPlayer))
        }
      " {\"source\":1,\"controller\":4,\"timestamp\":2,\"expiry\":{\"type\":\"AtTurnOf\",\"value\":4},\"affected\":{\"type\":\"Matching\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}},\"aimedAt\":{\"defenders\":{\"type\":\"Scoped\",\"value\":{\"type\":\"You\"}},\"kinds\":[{\"type\":\"OfPlayer\"}]}} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s ActiveAttackProhibition.codec
