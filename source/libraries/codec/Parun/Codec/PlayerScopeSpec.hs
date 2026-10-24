module Parun.Codec.PlayerScopeSpec where

import qualified Parun.Codec.PlayerScope as PlayerScope
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Comparison as Comparison
import qualified Parun.Types.PlayerMeasure as PlayerMeasure
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.PlayerScope as PlayerScope
import qualified Parun.Types.Superlative as Superlative
import qualified Parun.Types.TurnRole as TurnRole

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PlayerScope" $ do
  Spec.it s "You" $
    Common.assertCodec
      s
      PlayerScope.codec
      (PlayerScope.Related PlayerRelation.You)
      " {\"type\":\"You\"} "
  Spec.it s "Opponent" $
    Common.assertCodec
      s
      PlayerScope.codec
      (PlayerScope.Related PlayerRelation.Opponent)
      " {\"type\":\"Opponent\"} "
  Spec.it s "AnyPlayer" $
    Common.assertCodec
      s
      PlayerScope.codec
      (PlayerScope.Related PlayerRelation.AnyPlayer)
      " {\"type\":\"AnyPlayer\"} "
  Spec.it s "Superlative" $
    Common.assertCodec
      s
      PlayerScope.codec
      (PlayerScope.Superlative (Superlative.MkSuperlative PlayerMeasure.PermanentsControlled Comparison.GreaterThan))
      " {\"type\":\"Superlative\",\"value\":{\"measure\":{\"type\":\"PermanentsControlled\"},\"comparison\":{\"type\":\"GreaterThan\"}}} "
  -- Exhaustive over the relation, whose arms the codec derives: this is what
  -- would catch a relation the derivation missed, or one spelled unlike the
  -- relation's own tag.
  Spec.it s "speaks every relation under the relation's own tag" $
    mapM_
      (\relation -> Common.assertCodec s PlayerScope.codec (PlayerScope.Related relation) (" {\"type\":\"" <> show relation <> "\"} "))
      [minBound .. maxBound :: PlayerRelation.PlayerRelation]
  -- Siren's Call's "the active player" (CR 102.1, 805.9).
  Spec.it s "InRole" $
    Common.assertCodec
      s
      PlayerScope.codec
      (PlayerScope.InRole TurnRole.Active)
      " {\"type\":\"InRole\",\"value\":{\"type\":\"Active\"}} "
  -- Booby Trap's "the chosen player" (CR 607.2d).
  Spec.it s "ChosenPlayer" $
    Common.assertCodec
      s
      PlayerScope.codec
      PlayerScope.ChosenPlayer
      " {\"type\":\"ChosenPlayer\"} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s PlayerScope.codec
