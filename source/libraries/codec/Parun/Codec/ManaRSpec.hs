module Parun.Codec.ManaRSpec where

import qualified Parun.Codec.ManaR as ManaR
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.ManaR as ManaR
import qualified Parun.Types.ManaType as ManaType

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ManaR" $ do
  -- CR 106.12b: Ritual of Subdual.
  Spec.it s "MkManaR" $
    Common.assertCodec
      s
      ManaR.codec
      (ManaR.MkManaR (Filter.HasCardType CardType.Land) ManaType.Colorless)
      " {\"matching\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Land\"}},\"produces\":{\"type\":\"Colorless\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s ManaR.codec
