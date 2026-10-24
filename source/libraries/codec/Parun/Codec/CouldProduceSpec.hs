module Parun.Codec.CouldProduceSpec where

import qualified Parun.Codec.CouldProduce as CouldProduce
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.CouldProduce as CouldProduce
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.ManaFilter as ManaFilter
import qualified Parun.Types.ManaType as ManaType

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CouldProduce" $ do
  Spec.it s "MkCouldProduce, every key" $
    Common.assertCodec
      s
      CouldProduce.codec
      ( CouldProduce.MkCouldProduce
          { CouldProduce.among = Filter.HasCardType CardType.Land,
            CouldProduce.types = ManaFilter.NotOfType ManaType.Colorless
          }
      )
      " {\"among\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Land\"}},\"types\":{\"type\":\"NotOfType\",\"value\":{\"type\":\"Colorless\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s CouldProduce.codec
