module Parun.Codec.PermanentsBecomeTargetedSpec where

import qualified Parun.Codec.PermanentsBecomeTargeted as PermanentsBecomeTargeted
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Holder as Holder
import qualified Parun.Types.PermanentsBecomeTargeted as PermanentsBecomeTargeted
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.StackObjectKind as StackObjectKind

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PermanentsBecomeTargeted" $ do
  -- Professor Hojo's, both fields narrowed.
  Spec.it s "MkPermanentsBecomeTargeted, creatures you control and an activated ability" $
    Common.assertCodec
      s
      PermanentsBecomeTargeted.codec
      ( PermanentsBecomeTargeted.MkPermanentsBecomeTargeted
          { PermanentsBecomeTargeted.filter = Filter.And [Filter.HasCardType CardType.Creature, Filter.HeldBy Holder.Controller PlayerRelation.You],
            PermanentsBecomeTargeted.relation = PlayerRelation.AnyPlayer,
            PermanentsBecomeTargeted.kind = Just StackObjectKind.ActivatedAbility,
            PermanentsBecomeTargeted.includesYou = False
          }
      )
      " {\"filter\":{\"type\":\"And\",\"value\":[{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},{\"type\":\"HeldBy\",\"value\":{\"holder\":{\"type\":\"Controller\"},\"relation\":{\"type\":\"You\"}}}]},\"relation\":{\"type\":\"AnyPlayer\"},\"kind\":{\"type\":\"ActivatedAbility\"}} "
  -- The kind elided, which is the wider "a spell or ability" reading, and an
  -- opponent's: Diffusion Sliver's.
  Spec.it s "MkPermanentsBecomeTargeted, an opponent's and no kind at all" $
    Common.assertCodec
      s
      PermanentsBecomeTargeted.codec
      ( PermanentsBecomeTargeted.MkPermanentsBecomeTargeted
          { PermanentsBecomeTargeted.filter = Filter.IsSource,
            PermanentsBecomeTargeted.relation = PlayerRelation.Opponent,
            PermanentsBecomeTargeted.kind = Nothing,
            PermanentsBecomeTargeted.includesYou = False
          }
      )
      " {\"filter\":{\"type\":\"IsSource\"},\"relation\":{\"type\":\"Opponent\"}} "
  -- Leyline of Combustion's "you and/or at least one permanent you control".
  Spec.it s "MkPermanentsBecomeTargeted, you included" $
    Common.assertCodec
      s
      PermanentsBecomeTargeted.codec
      ( PermanentsBecomeTargeted.MkPermanentsBecomeTargeted
          { PermanentsBecomeTargeted.filter = Filter.IsSource,
            PermanentsBecomeTargeted.relation = PlayerRelation.Opponent,
            PermanentsBecomeTargeted.kind = Nothing,
            PermanentsBecomeTargeted.includesYou = True
          }
      )
      " {\"filter\":{\"type\":\"IsSource\"},\"relation\":{\"type\":\"Opponent\"},\"includesYou\":true} "
  Spec.it s "has a schema" $ Common.assertHasSchema s PermanentsBecomeTargeted.codec
