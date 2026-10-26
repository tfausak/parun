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
            PermanentsBecomeTargeted.kind = Just StackObjectKind.ActivatedAbility
          }
      )
      " {\"filter\":{\"type\":\"And\",\"value\":[{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},{\"type\":\"HeldBy\",\"value\":{\"holder\":{\"type\":\"Controller\"},\"relation\":{\"type\":\"You\"}}}]},\"kind\":{\"type\":\"ActivatedAbility\"}} "
  -- The kind elided, which is the wider "a spell or ability" reading.
  Spec.it s "MkPermanentsBecomeTargeted, no kind at all" $
    Common.assertCodec
      s
      PermanentsBecomeTargeted.codec
      ( PermanentsBecomeTargeted.MkPermanentsBecomeTargeted
          { PermanentsBecomeTargeted.filter = Filter.IsSource,
            PermanentsBecomeTargeted.kind = Nothing
          }
      )
      " {\"filter\":{\"type\":\"IsSource\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s PermanentsBecomeTargeted.codec
