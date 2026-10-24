module Parun.Codec.EntryPriceSpec where

import qualified Parun.Codec.EntryPrice as EntryPrice
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.EntryPrice as EntryPrice
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Subtype as Subtype

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.EntryPrice" $ do
  Spec.it s "PayLife (Razorgrass Field)" $
    Common.assertCodec s EntryPrice.codec (EntryPrice.PayLife 3) " {\"type\":\"PayLife\",\"value\":3} "
  Spec.it s "Reveal (Rustic Clachan)" $
    Common.assertCodec
      s
      EntryPrice.codec
      (EntryPrice.Reveal (Filter.HasSubtype Subtype.Kithkin))
      " {\"type\":\"Reveal\",\"value\":{\"type\":\"HasSubtype\",\"value\":{\"type\":\"Kithkin\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s EntryPrice.codec
