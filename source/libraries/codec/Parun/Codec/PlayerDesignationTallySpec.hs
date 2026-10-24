module Parun.Codec.PlayerDesignationTallySpec where

import qualified Parun.Codec.PlayerDesignationTally as PlayerDesignationTally
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.PlayerDesignation as PlayerDesignation
import qualified Parun.Types.PlayerDesignationTally as PlayerDesignationTally
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PlayerDesignationTally" $ do
  -- CR 702.131c / 702.195b: whether a player has one of the two rest-of-game
  -- marks -- a LEAF, so nothing here is a Quantity.
  Spec.it s "MkPlayerDesignationTally" $
    Common.assertCodec
      s
      PlayerDesignationTally.codec
      ( PlayerDesignationTally.MkPlayerDesignationTally
          { PlayerDesignationTally.player = PlayerRef.Relative PlayerRelation.You,
            PlayerDesignationTally.designation = PlayerDesignation.CitysBlessing
          }
      )
      " {\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"designation\":{\"type\":\"CitysBlessing\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s PlayerDesignationTally.codec
