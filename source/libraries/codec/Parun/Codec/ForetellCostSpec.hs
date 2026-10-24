module Parun.Codec.ForetellCostSpec where

import qualified Parun.Codec.ForetellCost as ForetellCost
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.ForetellCost as ForetellCost
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaSymbol as ManaSymbol

-- | Instantiated at 'Keyword.Keyword', the only concrete instantiation anywhere
-- in the pool.
codec :: Codec.Codec (ForetellCost.ForetellCost Keyword.Keyword)
codec = ForetellCost.codec Keyword.codec

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ForetellCost" $ do
  Spec.it s "Stated" $
    Common.assertCodec
      s
      codec
      (ForetellCost.Stated (Cost.MkCost (Just (ManaCost.MkManaCost [ManaSymbol.Generic 1])) []))
      " {\"type\":\"Stated\",\"value\":{\"mana\":[{\"type\":\"Generic\",\"value\":1}]}} "
  Spec.it s "ManaCostReducedBy" $
    Common.assertCodec
      s
      codec
      (ForetellCost.ManaCostReducedBy (ManaCost.MkManaCost [ManaSymbol.Generic 2]))
      " {\"type\":\"ManaCostReducedBy\",\"value\":[{\"type\":\"Generic\",\"value\":2}]} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
