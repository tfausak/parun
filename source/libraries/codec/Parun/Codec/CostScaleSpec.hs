module Parun.Codec.CostScaleSpec where

import qualified Parun.Codec.CostScale as CostScale
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Color as Color
import qualified Parun.Types.CostScale as CostScale

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CostScale" $ do
  Spec.it s "Once" $
    Common.assertCodec
      s
      CostScale.codec
      CostScale.Once
      " {\"type\":\"Once\"} "
  -- Drought's "for each black mana symbol". Black rather than a colour picked at
  -- random: it is the one a card in the pool writes.
  Spec.it s "PerColoredSymbol" $
    Common.assertCodec
      s
      CostScale.codec
      (CostScale.PerColoredSymbol Color.Black)
      " {\"type\":\"PerColoredSymbol\",\"value\":{\"type\":\"Black\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s CostScale.codec
