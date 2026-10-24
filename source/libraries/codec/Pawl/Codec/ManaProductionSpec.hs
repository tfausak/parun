module Pawl.Codec.ManaProductionSpec where

import qualified Pawl.Codec.ManaProduction as ManaProduction
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.CardType as CardType
import qualified Pawl.Types.Color as Color
import qualified Pawl.Types.CouldProduce as CouldProduce
import qualified Pawl.Types.Filter as Filter
import qualified Pawl.Types.ManaFilter as ManaFilter
import qualified Pawl.Types.ManaProduction as ManaProduction
import qualified Pawl.Types.ManaType as ManaType

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.ManaProduction" $ do
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
