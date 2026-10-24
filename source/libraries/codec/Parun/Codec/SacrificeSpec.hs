module Parun.Codec.SacrificeSpec where

import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.Sacrifice as Sacrifice
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CostAmount as CostAmount
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.Sacrifice as Sacrifice
import qualified Parun.Types.Subtype as Subtype

-- | Instantiated at 'Keyword.Keyword', the only concrete instantiation anywhere
-- in the pool.
codec :: Codec.Codec (Sacrifice.Sacrifice Keyword.Keyword)
codec = Sacrifice.codec Keyword.codec

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Sacrifice" $ do
  -- CR 701.21a: Fireblast's two Mountains. The count is HOW MANY, matched exactly.
  Spec.it s "MkSacrifice" $
    Common.assertCodec
      s
      codec
      ( Sacrifice.MkSacrifice
          { Sacrifice.count = CostAmount.Fixed 2,
            Sacrifice.whichPermanents = Filter.HasSubtype Subtype.Mountain
          }
      )
      " {\"count\":{\"type\":\"Fixed\",\"value\":2},\"whichPermanents\":{\"type\":\"HasSubtype\",\"value\":{\"type\":\"Mountain\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
