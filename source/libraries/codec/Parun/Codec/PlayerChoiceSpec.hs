module Parun.Codec.PlayerChoiceSpec where

import qualified Parun.Codec.PlayerChoice as PlayerChoice
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Gift as Gift
import qualified Parun.Types.KeywordInstance as KeywordInstance
import qualified Parun.Types.PlayerChoice as PlayerChoice

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PlayerChoice" $ do
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
      (PlayerChoice.Promised Gift.Card (KeywordInstance.Own 2))
      " {\"type\":\"Promised\",\"value\":[{\"type\":\"Card\"},{\"type\":\"Own\",\"value\":2}]} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s PlayerChoice.codec
