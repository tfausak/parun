module Parun.Codec.ManaProductionSpec where

import qualified Parun.Codec.ManaProduction as ManaProduction
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Color as Color
import qualified Parun.Types.CouldProduce as CouldProduce
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.ManaFilter as ManaFilter
import qualified Parun.Types.ManaProduction as ManaProduction
import qualified Parun.Types.ManaType as ManaType

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ManaProduction" $ do
  Spec.it s "OfType" $
    Common.assertCodec
      s
      ManaProduction.codec
      (ManaProduction.OfType (ManaType.Colored Color.Green))
      " {\"type\":\"OfType\",\"value\":{\"type\":\"Colored\",\"value\":{\"type\":\"Green\"}}} "
  Spec.it s "AnyColor" $
    Common.assertCodec
      s
      ManaProduction.codec
      ManaProduction.AnyColor
      " {\"type\":\"AnyColor\"} "
  Spec.it s "Chosen" $
    Common.assertCodec
      s
      ManaProduction.codec
      ManaProduction.Chosen
      " {\"type\":\"Chosen\"} "
  Spec.it s "SnowSymbol" $
    Common.assertCodec
      s
      ManaProduction.codec
      ManaProduction.SnowSymbol
      " {\"type\":\"SnowSymbol\"} "
  Spec.it s "Noted" $
    Common.assertCodec
      s
      ManaProduction.codec
      ManaProduction.Noted
      " {\"type\":\"Noted\"} "
  Spec.it s "CouldProduce" $
    Common.assertCodec
      s
      ManaProduction.codec
      (ManaProduction.CouldProduce (CouldProduce.MkCouldProduce (Filter.HasCardType CardType.Land) ManaFilter.Any))
      " {\"type\":\"CouldProduce\",\"value\":{\"among\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Land\"}},\"types\":{\"type\":\"Any\"}}} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s ManaProduction.codec
