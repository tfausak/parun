module Parun.Codec.ControllerBecomesTargetSpec where

import qualified Parun.Codec.ControllerBecomesTarget as ControllerBecomesTarget
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ControllerBecomesTarget as ControllerBecomesTarget
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.StackObjectKind as StackObjectKind

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ControllerBecomesTarget" $ do
  -- Amulet of Safekeeping's "a spell or ability an opponent controls". The kind
  -- is ELIDED when absent, which is what this case pins.
  Spec.it s "MkControllerBecomesTarget, a spell or ability alike" $
    Common.assertCodec
      s
      ControllerBecomesTarget.codec
      ( ControllerBecomesTarget.MkControllerBecomesTarget
          { ControllerBecomesTarget.relation = PlayerRelation.Opponent,
            ControllerBecomesTarget.kind = Nothing
          }
      )
      " {\"relation\":{\"type\":\"Opponent\"}} "
  -- Dormant Gomazoa's "a spell", from any player. Here the kind is written,
  -- which is what pins the key.
  Spec.it s "MkControllerBecomesTarget, a spell only" $
    Common.assertCodec
      s
      ControllerBecomesTarget.codec
      ( ControllerBecomesTarget.MkControllerBecomesTarget
          { ControllerBecomesTarget.relation = PlayerRelation.AnyPlayer,
            ControllerBecomesTarget.kind = Just StackObjectKind.Spell
          }
      )
      " {\"relation\":{\"type\":\"AnyPlayer\"},\"kind\":{\"type\":\"Spell\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s ControllerBecomesTarget.codec
