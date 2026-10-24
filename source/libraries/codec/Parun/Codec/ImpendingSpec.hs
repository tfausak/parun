module Parun.Codec.ImpendingSpec where

import qualified Parun.Codec.Impending as Impending
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Color as Color
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.Impending as Impending
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaSymbol as ManaSymbol
import qualified Parun.Types.ManaType as ManaType

-- | Instantiated at 'Keyword.Keyword', the only concrete instantiation anywhere
-- in the pool.
codec :: Codec.Codec (Impending.Impending Keyword.Keyword)
codec = Impending.codec Keyword.codec

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Impending" $ do
  -- CR 702.176a: Overlord of the Mistmoors' "Impending 4--{2}{W}{W}".
  Spec.it s "MkImpending" $
    Common.assertCodec
      s
      codec
      ( Impending.MkImpending
          { Impending.counters = 4,
            Impending.cost = Cost.MkCost {Cost.mana = Just (ManaCost.MkManaCost [ManaSymbol.Generic 2, white, white]), Cost.components = []}
          }
      )
      " {\"counters\":4,\"cost\":{\"mana\":[{\"type\":\"Generic\",\"value\":2},{\"type\":\"OfType\",\"value\":{\"type\":\"Colored\",\"value\":{\"type\":\"White\"}}},{\"type\":\"OfType\",\"value\":{\"type\":\"Colored\",\"value\":{\"type\":\"White\"}}}]}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec

white :: ManaSymbol.ManaSymbol
white = ManaSymbol.OfType (ManaType.Colored Color.White)
