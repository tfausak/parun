module Parun.Codec.RequireAttackSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.RequireAttack as RequireAttack
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AttackTargetRef as AttackTargetRef
import qualified Parun.Types.Duration as Duration
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.RequireAttack as RequireAttack
import qualified Parun.Types.RestrictedCreatures as RestrictedCreatures
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.RequireAttack" $ do
  -- CR 508.1d, Alluring Siren's sentence.
  Spec.it s "MkRequireAttack, all three keys" $
    Common.assertCodec
      s
      RequireAttack.codec
      ( RequireAttack.MkRequireAttack
          { RequireAttack.duration = Duration.UntilEndOfTurn,
            RequireAttack.attacker = RestrictedCreatures.Named (ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "target"))),
            RequireAttack.defender = Just (AttackTargetRef.Players (PlayerRef.Relative PlayerRelation.You))
          }
      )
      " {\"duration\":{\"type\":\"UntilEndOfTurn\"},\"attacker\":{\"type\":\"Named\",\"value\":{\"type\":\"InSlot\",\"value\":\"target\"}},\"defender\":{\"type\":\"Players\",\"value\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}}}} "
  -- Courtly Provocateur's "attacks this turn if able": no defender, elided.
  Spec.it s "MkRequireAttack, no defender" $
    Common.assertCodec
      s
      RequireAttack.codec
      ( RequireAttack.MkRequireAttack
          { RequireAttack.duration = Duration.UntilEndOfTurn,
            RequireAttack.attacker = RestrictedCreatures.Named (ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "target"))),
            RequireAttack.defender = Nothing
          }
      )
      " {\"duration\":{\"type\":\"UntilEndOfTurn\"},\"attacker\":{\"type\":\"Named\",\"value\":{\"type\":\"InSlot\",\"value\":\"target\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s RequireAttack.codec
