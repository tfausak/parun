module Parun.Codec.ExchangeSidesSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.ExchangeSides as ExchangeSides
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ExchangeSides as ExchangeSides
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ExchangeSides" $ do
  Spec.it s "WithController" $
    Common.assertCodec
      s
      ExchangeSides.codec
      (ExchangeSides.WithController (SlotName.MkSlotName (Text.pack "target")))
      " {\"type\":\"WithController\",\"value\":\"target\"} "
  Spec.it s "BetweenTargets" $
    Common.assertCodec
      s
      ExchangeSides.codec
      (ExchangeSides.BetweenTargets (SlotName.MkSlotName (Text.pack "players")))
      " {\"type\":\"BetweenTargets\",\"value\":\"players\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s ExchangeSides.codec
