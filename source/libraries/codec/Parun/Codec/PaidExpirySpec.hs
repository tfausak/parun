module Parun.Codec.PaidExpirySpec where

import qualified Parun.Codec.PaidExpiry as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Color as Color
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaSymbol as ManaSymbol
import qualified Parun.Types.ManaType as ManaType
import qualified Parun.Types.PaidExpiry as PaidExpiry
import qualified Parun.Types.PlayerId as PlayerId

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PaidExpiry" $ do
  -- CR 116.2c's price and CR 109.5's baked seat. Runtime-only, Parun.Codec.While's
  -- situation: the one thing that serialises this is a DelayedTrigger (CR 603.7b).
  Spec.it s "MkPaidExpiry, both keys" $
    Common.assertCodec
      s
      Codec.codec
      ( PaidExpiry.MkPaidExpiry
          { PaidExpiry.player = PlayerId.MkPlayerId 0,
            PaidExpiry.cost = Cost.MkCost (Just (ManaCost.MkManaCost [ManaSymbol.OfType (ManaType.Colored Color.Blue)])) []
          }
      )
      " {\"player\":0,\"cost\":{\"mana\":[{\"type\":\"OfType\",\"value\":{\"type\":\"Colored\",\"value\":{\"type\":\"Blue\"}}}]}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s Codec.codec
