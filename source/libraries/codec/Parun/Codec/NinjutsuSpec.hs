module Parun.Codec.NinjutsuSpec where

import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.Ninjutsu as Ninjutsu
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaSymbol as ManaSymbol
import qualified Parun.Types.Ninjutsu as Ninjutsu
import qualified Parun.Types.NinjutsuVariant as NinjutsuVariant

-- | Instantiated at 'Keyword.Keyword', the only concrete instantiation anywhere
-- in the pool.
codec :: Codec.Codec (Ninjutsu.Ninjutsu Keyword.Keyword)
codec = Ninjutsu.codec Keyword.codec

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Ninjutsu" $ do
  -- CR 702.49d: "Commander ninjutsu {1}".
  Spec.it s "MkNinjutsu" $
    Common.assertCodec
      s
      codec
      ( Ninjutsu.MkNinjutsu
          { Ninjutsu.cost = Cost.MkCost {Cost.mana = Just (ManaCost.MkManaCost [ManaSymbol.Generic 1]), Cost.components = []},
            Ninjutsu.variant = NinjutsuVariant.Commander
          }
      )
      " {\"cost\":{\"mana\":[{\"type\":\"Generic\",\"value\":1}]},\"variant\":{\"type\":\"Commander\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
