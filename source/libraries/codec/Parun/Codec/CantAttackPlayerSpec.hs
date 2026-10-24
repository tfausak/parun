module Parun.Codec.CantAttackPlayerSpec where

import qualified Data.Set as Set
import qualified Parun.Codec.CantAttackPlayer as CantAttackPlayer
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Affected as Affected
import qualified Parun.Types.AttackTargetKind as AttackTargetKind
import qualified Parun.Types.CantAttackPlayer as CantAttackPlayer
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.PlayerScope as PlayerScope

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CantAttackPlayer" $ do
  -- CR 508.1c's attacking pairwise restriction, Vow of Flight's payload. The
  -- scope is You rather than AnyPlayer, which is the value that would read the
  -- same as a blanket "can't attack" on any board, and the kinds are two of CR
  -- 506.3's three, which is what a one-element list would not distinguish from
  -- a sorted singleton.
  Spec.it s "MkCantAttackPlayer, unless elided" $
    Common.assertCodec
      s
      CantAttackPlayer.codec
      ( CantAttackPlayer.MkCantAttackPlayer
          { CantAttackPlayer.affected = Affected.Matching (Filter.HasCardType CardType.Creature),
            CantAttackPlayer.defenders = PlayerScope.Related PlayerRelation.You,
            CantAttackPlayer.kinds = Set.fromList [AttackTargetKind.OfPlayer, AttackTargetKind.OfPlaneswalker],
            CantAttackPlayer.unless = Nothing,
            CantAttackPlayer.name = Nothing
          }
      )
      " {\"affected\":{\"type\":\"Matching\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}},\"defenders\":{\"type\":\"You\"},\"kinds\":[{\"type\":\"OfPlayer\"},{\"type\":\"OfPlaneswalker\"}]} "
  Spec.it s "has a schema" $ Common.assertHasSchema s CantAttackPlayer.codec
