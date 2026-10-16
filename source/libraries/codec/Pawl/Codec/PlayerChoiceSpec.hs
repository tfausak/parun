module Pawl.Codec.PlayerChoiceSpec where

import qualified Pawl.Codec.PlayerChoice as PlayerChoice
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.Gift as Gift
import qualified Pawl.Types.PlayerChoice as PlayerChoice

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.PlayerChoice" $ do
  Spec.it s "AsEnters" $
    Common.assertCodec
      s
      PlayerChoice.codec
      PlayerChoice.AsEnters
      " {\"type\":\"AsEnters\"} "
  Spec.it s "Promised" $
    Common.assertCodec
      s
      PlayerChoice.codec
      (PlayerChoice.Promised Gift.Card 2)
      " {\"type\":\"Promised\",\"value\":[{\"type\":\"Card\"},2]} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s PlayerChoice.codec
