module Pawl.Codec.CouldProduceSpec where

import qualified Pawl.Codec.CouldProduce as CouldProduce
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.CardType as CardType
import qualified Pawl.Types.CouldProduce as CouldProduce
import qualified Pawl.Types.Filter as Filter
import qualified Pawl.Types.ManaFilter as ManaFilter
import qualified Pawl.Types.ManaType as ManaType

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.CouldProduce" $ do
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
