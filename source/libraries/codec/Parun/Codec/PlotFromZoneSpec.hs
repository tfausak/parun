module Parun.Codec.PlotFromZoneSpec where

import qualified Parun.Codec.PlotFromZone as PlotFromZone
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.InZone as InZone
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.PlotFromZone as PlotFromZone
import qualified Parun.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PlotFromZone" $ do
  -- Fblthp, Lost on the Range's shape: nonland cards from the top of your library.
  Spec.it s "MkPlotFromZone" $
    Common.assertCodec
      s
      PlotFromZone.codec
      ( PlotFromZone.MkPlotFromZone
          { PlotFromZone.from = InZone.MkInZone {InZone.zone = Zone.Library, InZone.player = PlayerRef.Relative PlayerRelation.You},
            PlotFromZone.matching = Filter.Not (Filter.HasCardType CardType.Land)
          }
      )
      " {\"from\":{\"zone\":{\"type\":\"Library\"},\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}}},\"matching\":{\"type\":\"Not\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Land\"}}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s PlotFromZone.codec
