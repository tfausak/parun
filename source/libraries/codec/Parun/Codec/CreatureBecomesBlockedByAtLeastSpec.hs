module Parun.Codec.CreatureBecomesBlockedByAtLeastSpec where

import qualified Parun.Codec.CreatureBecomesBlockedByAtLeast as CreatureBecomesBlockedByAtLeast
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CreatureBecomesBlockedByAtLeast as CreatureBecomesBlockedByAtLeast
import qualified Parun.Types.PlayerRelation as PlayerRelation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CreatureBecomesBlockedByAtLeast" $ do
  -- Seifer, Balamb Rival's payload: whom the attacker is attacking, and the
  -- floor on how many creatures block it.
  Spec.it s "MkCreatureBecomesBlockedByAtLeast, both keys" $
    Common.assertCodec
      s
      CreatureBecomesBlockedByAtLeast.codec
      ( CreatureBecomesBlockedByAtLeast.MkCreatureBecomesBlockedByAtLeast
          { CreatureBecomesBlockedByAtLeast.attacked = PlayerRelation.Opponent,
            CreatureBecomesBlockedByAtLeast.blockers = 2
          }
      )
      " {\"attacked\":{\"type\":\"Opponent\"},\"blockers\":2} "
  Spec.it s "has a schema" $ Common.assertHasSchema s CreatureBecomesBlockedByAtLeast.codec
