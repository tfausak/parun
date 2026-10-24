module Parun.Codec.AnyNumberDiscardSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.AnyNumberDiscard as AnyNumberDiscard
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AnyNumberDiscard as AnyNumberDiscard
import qualified Parun.Types.AnyNumberMatching as AnyNumberMatching
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AnyNumberDiscard" $ do
  Spec.it s "MkAnyNumberDiscard, no ceiling and no bound slot" $
    Common.assertCodec
      s
      AnyNumberDiscard.codec
      ( AnyNumberDiscard.MkAnyNumberDiscard
          { AnyNumberDiscard.player = PlayerRef.Relative PlayerRelation.You,
            AnyNumberDiscard.cards = AnyNumberMatching.MkAnyNumberMatching (Filter.HasCardType CardType.Land) Nothing,
            AnyNumberDiscard.discarded = Nothing
          }
      )
      " {\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"cards\":{\"filter\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Land\"}}}} "
  Spec.it s "MkAnyNumberDiscard, with a ceiling and the discarded slot" $
    Common.assertCodec
      s
      AnyNumberDiscard.codec
      ( AnyNumberDiscard.MkAnyNumberDiscard
          { AnyNumberDiscard.player = PlayerRef.Relative PlayerRelation.You,
            AnyNumberDiscard.cards = AnyNumberMatching.MkAnyNumberMatching (Filter.HasCardType CardType.Land) (Just (Quantity.Literal 2)),
            AnyNumberDiscard.discarded = Just (SlotName.MkSlotName (Text.pack "discarded"))
          }
      )
      " {\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"cards\":{\"filter\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Land\"}},\"atMost\":{\"type\":\"Literal\",\"value\":2}},\"discarded\":\"discarded\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s AnyNumberDiscard.codec
