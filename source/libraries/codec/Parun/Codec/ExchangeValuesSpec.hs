module Parun.Codec.ExchangeValuesSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.ExchangeValues as ExchangeValues
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Duration as Duration
import qualified Parun.Types.ExchangeValues as ExchangeValues
import qualified Parun.Types.ExchangedValue as ExchangedValue
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ExchangeValues" $ do
  Spec.it s "MkExchangeValues" $
    Common.assertCodec
      s
      ExchangeValues.codec
      ( ExchangeValues.MkExchangeValues
          { ExchangeValues.one = ExchangedValue.LifeTotal (PlayerRef.Relative PlayerRelation.You),
            ExchangeValues.other = ExchangedValue.Toughness (ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "self"))),
            ExchangeValues.duration = Duration.Indefinite
          }
      )
      " {\"one\":{\"type\":\"LifeTotal\",\"value\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}}},\"other\":{\"type\":\"Toughness\",\"value\":{\"type\":\"InSlot\",\"value\":\"self\"}}} "
  Spec.it s "with a duration" $
    Common.assertCodec
      s
      ExchangeValues.codec
      ( ExchangeValues.MkExchangeValues
          { ExchangeValues.one = ExchangedValue.Power (ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "self"))),
            ExchangeValues.other = ExchangedValue.Power (ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "target"))),
            ExchangeValues.duration = Duration.UntilEndOfCombat
          }
      )
      " {\"duration\":{\"type\":\"UntilEndOfCombat\"},\"one\":{\"type\":\"Power\",\"value\":{\"type\":\"InSlot\",\"value\":\"self\"}},\"other\":{\"type\":\"Power\",\"value\":{\"type\":\"InSlot\",\"value\":\"target\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s ExchangeValues.codec
