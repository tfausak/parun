module Parun.Codec.CastRepetitionSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.CastRepetition as CastRepetition
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CastRepetition as CastRepetition
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CastRepetition" $ do
  Spec.it s "Once" $
    Common.assertCodec
      s
      CastRepetition.codec
      CastRepetition.Once
      " {\"type\":\"Once\"} "
  Spec.it s "AnyNumber" $
    Common.assertCodec
      s
      CastRepetition.codec
      CastRepetition.AnyNumber
      " {\"type\":\"AnyNumber\"} "
  Spec.it s "WithinTotalManaValue" $
    Common.assertCodec
      s
      CastRepetition.codec
      (CastRepetition.WithinTotalManaValue (Quantity.InSlot (SlotName.MkSlotName (Text.pack "X"))))
      " {\"type\":\"WithinTotalManaValue\",\"value\":{\"type\":\"InSlot\",\"value\":\"X\"}} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s CastRepetition.codec
