module Pawl.Codec.PlayerScopeSpec where

import qualified Pawl.Codec.PlayerScope as PlayerScope
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.Comparison as Comparison
import qualified Pawl.Types.PlayerMeasure as PlayerMeasure
import qualified Pawl.Types.PlayerRelation as PlayerRelation
import qualified Pawl.Types.PlayerScope as PlayerScope
import qualified Pawl.Types.Superlative as Superlative
import qualified Pawl.Types.TurnRole as TurnRole

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.PlayerScope" $ do
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
  Spec.it s "has a schema" $
    Common.assertHasSchema s PlayerScope.codec
