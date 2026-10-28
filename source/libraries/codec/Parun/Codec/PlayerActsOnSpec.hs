module Parun.Codec.PlayerActsOnSpec where

import qualified Parun.Codec.PlayerActsOn as PlayerActsOn
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.PlayerActsOn as PlayerActsOn
import qualified Parun.Types.PlayerRelation as PlayerRelation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PlayerActsOn" $ do
  -- Vengeful Tracker's payload: whose sacrifice fires it, and the quality the
  -- sacrificed permanent has to have.
  Spec.it s "MkPlayerActsOn, both keys" $
    Common.assertCodec
      s
      PlayerActsOn.codec
      ( PlayerActsOn.MkPlayerActsOn
          { PlayerActsOn.player = PlayerRelation.Opponent,
            PlayerActsOn.filter = Filter.HasCardType CardType.Artifact
          }
      )
      " {\"player\":{\"type\":\"Opponent\"},\"filter\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Artifact\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s PlayerActsOn.codec
