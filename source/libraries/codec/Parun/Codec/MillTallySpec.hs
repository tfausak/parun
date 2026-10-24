module Parun.Codec.MillTallySpec where

import qualified Data.Text as Text
import qualified Parun.Codec.MillTally as MillTally
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.MillTally as MillTally
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.MillTally" $ do
  -- CR 728.1's own tally: "for each NONLAND card milled this way".
  Spec.it s "MkMillTally, a slot and a filter" $
    Common.assertCodec
      s
      MillTally.codec
      MillTally.MkMillTally
        { MillTally.slot = SlotName.MkSlotName (Text.pack "milled"),
          MillTally.filter = Filter.Not (Filter.HasCardType CardType.Land)
        }
      " {\"slot\":\"milled\",\"filter\":{\"type\":\"Not\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Land\"}}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s MillTally.codec
