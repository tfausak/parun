module Parun.Codec.SpliceSpec where

import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.Splice as Splice
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Color as Color
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaSymbol as ManaSymbol
import qualified Parun.Types.ManaType as ManaType
import qualified Parun.Types.Splice as Splice
import qualified Parun.Types.Subtype as Subtype

-- | Instantiated at 'Keyword.Keyword', the only concrete instantiation anywhere
-- in the pool.
codec :: Codec.Codec (Splice.Splice Keyword.Keyword)
codec = Splice.codec Keyword.codec

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Splice" $ do
  -- CR 702.47a: Desperate Ritual's "Splice onto Arcane {1}{R}".
  Spec.it s "MkSplice" $
    Common.assertCodec
      s
      codec
      ( Splice.MkSplice
          { Splice.onto = Filter.HasSubtype Subtype.Arcane,
            Splice.cost = Cost.MkCost {Cost.mana = Just (ManaCost.MkManaCost [ManaSymbol.Generic 1, ManaSymbol.OfType (ManaType.Colored Color.Red)]), Cost.components = []}
          }
      )
      " {\"onto\":{\"type\":\"HasSubtype\",\"value\":{\"type\":\"Arcane\"}},\"cost\":{\"mana\":[{\"type\":\"Generic\",\"value\":1},{\"type\":\"OfType\",\"value\":{\"type\":\"Colored\",\"value\":{\"type\":\"Red\"}}}]}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
