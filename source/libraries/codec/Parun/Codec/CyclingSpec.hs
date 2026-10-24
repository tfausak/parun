module Parun.Codec.CyclingSpec where

import qualified Parun.Codec.Cycling as Cycling
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.Cycling as Cycling
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaSymbol as ManaSymbol

-- | Instantiated at 'Keyword.Keyword', the only concrete instantiation anywhere
-- in the pool.
codec :: Codec.Codec (Cycling.Cycling Keyword.Keyword)
codec = Cycling.codec Keyword.codec

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Cycling" $ do
  -- CR 702.29a: plain cycling, so searchFor is Nothing.
  Spec.it s "MkCycling" $
    Common.assertCodec
      s
      codec
      ( Cycling.MkCycling
          { Cycling.cost = Cost.MkCost {Cost.mana = Just (ManaCost.MkManaCost [ManaSymbol.Generic 2]), Cost.components = []},
            Cycling.searchFor = Nothing
          }
      )
      " {\"cost\":{\"mana\":[{\"type\":\"Generic\",\"value\":2}]},\"searchFor\":null} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
