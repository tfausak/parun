module Parun.Codec.PlayerCountersAreSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.PlayerCountersAre as PlayerCountersAre
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Label as Label.Type
import qualified Parun.Types.PlayerCounterKind as PlayerCounterKind.Type
import qualified Parun.Types.PlayerCountersAre as PlayerCountersAre.Type

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PlayerCountersAre" $ do
  Spec.it s "a player, a kind and a count" $
    Common.assertCodec s PlayerCountersAre.codec (PlayerCountersAre.Type.MkPlayerCountersAre (Label.Type.MkLabel (Text.pack "bob")) PlayerCounterKind.Type.Poison 3) " {\"player\":\"bob\",\"kind\":{\"type\":\"Poison\"},\"count\":3} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s PlayerCountersAre.codec
