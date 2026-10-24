module Parun.Codec.ExchangeZonesSpec where

import qualified Parun.Codec.ExchangeZones as ExchangeZones
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ExchangeZones as ExchangeZones
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.ZonePair as ZonePair

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ExchangeZones" $ do
  Spec.it s "MkExchangeZones" $
    Common.assertCodec
      s
      ExchangeZones.codec
      ( ExchangeZones.MkExchangeZones
          { ExchangeZones.player = PlayerRef.Relative PlayerRelation.You,
            ExchangeZones.zones = ZonePair.GraveyardAndLibrary
          }
      )
      " {\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"zones\":{\"type\":\"GraveyardAndLibrary\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s ExchangeZones.codec
