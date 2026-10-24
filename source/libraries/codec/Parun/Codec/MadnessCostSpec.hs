module Parun.Codec.MadnessCostSpec where

import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.MadnessCost as MadnessCost
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.MadnessCost as MadnessCost
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaSymbol as ManaSymbol

-- | Instantiated at 'Keyword.Keyword', the only concrete instantiation anywhere
-- in the pool.
codec :: Codec.Codec (MadnessCost.MadnessCost Keyword.Keyword)
codec = MadnessCost.codec Keyword.codec

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.MadnessCost" $ do
  Spec.it s "Stated" $
    Common.assertCodec
      s
      codec
      (MadnessCost.Stated (Cost.MkCost (Just (ManaCost.MkManaCost [ManaSymbol.Generic 1])) []))
      " {\"type\":\"Stated\",\"value\":{\"mana\":[{\"type\":\"Generic\",\"value\":1}]}} "
  Spec.it s "OwnManaCost" $
    Common.assertCodec
      s
      codec
      MadnessCost.OwnManaCost
      " {\"type\":\"OwnManaCost\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
