module Parun.Codec.MorphSpec where

import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.Morph as Morph
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaSymbol as ManaSymbol
import qualified Parun.Types.Morph as Morph
import qualified Parun.Types.MorphVariant as MorphVariant

-- | Instantiated at 'Keyword.Keyword', the only concrete instantiation anywhere
-- in the pool.
codec :: Codec.Codec (Morph.Morph Keyword.Keyword)
codec = Morph.codec Keyword.codec

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Morph" $ do
  -- CR 702.37b: megamorph is this arm with a variant, not a sibling.
  Spec.it s "MkMorph" $
    Common.assertCodec
      s
      codec
      ( Morph.MkMorph
          { Morph.cost = Cost.MkCost {Cost.mana = Just (ManaCost.MkManaCost [ManaSymbol.Generic 3]), Cost.components = []},
            Morph.variant = MorphVariant.Mega
          }
      )
      " {\"cost\":{\"mana\":[{\"type\":\"Generic\",\"value\":3}]},\"variant\":{\"type\":\"Mega\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
