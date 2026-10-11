module Pawl.Codec.NinjutsuSpec where

import qualified Pawl.Codec.Keyword as Keyword
import qualified Pawl.Codec.Ninjutsu as Ninjutsu
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.Cost as Cost
import qualified Pawl.Types.Keyword as Keyword
import qualified Pawl.Types.ManaCost as ManaCost
import qualified Pawl.Types.ManaSymbol as ManaSymbol
import qualified Pawl.Types.Ninjutsu as Ninjutsu
import qualified Pawl.Types.NinjutsuVariant as NinjutsuVariant

-- | Instantiated at 'Keyword.Keyword', the only concrete instantiation anywhere
-- in the pool.
codec :: Codec.Codec (Ninjutsu.Ninjutsu Keyword.Keyword)
codec = Ninjutsu.codec Keyword.codec

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.Ninjutsu" $ do
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
