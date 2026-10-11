module Pawl.Codec.ExileFromGraveyardSpec where

import qualified Data.Text as Text
import qualified Pawl.Codec.ExileFromGraveyard as ExileFromGraveyard
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.CardType as CardType
import qualified Pawl.Types.CounterKind as CounterKind
import qualified Pawl.Types.ExileFromGraveyard as ExileFromGraveyard
import qualified Pawl.Types.Filter as Filter
import qualified Pawl.Types.HowMany as HowMany
import qualified Pawl.Types.PlayerRelation as PlayerRelation
import qualified Pawl.Types.PlayerScope as PlayerScope
import qualified Pawl.Types.Quantity as Quantity
import qualified Pawl.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.ExileFromGraveyard" $ do
  -- Living Lore: one card out of your graveyard, both defaults elided.
  Spec.it s "MkExileFromGraveyard, the defaults" $
    Common.assertCodec
      s
      ExileFromGraveyard.codec
      ( ExileFromGraveyard.MkExileFromGraveyard
          { ExileFromGraveyard.filter = Filter.HasCardType CardType.Instant,
            ExileFromGraveyard.players = PlayerScope.Related PlayerRelation.You,
            ExileFromGraveyard.count = HowMany.one,
            ExileFromGraveyard.orGraveyard = False,
            ExileFromGraveyard.kinds = [],
            ExileFromGraveyard.each = Quantity.Literal 1
          }
      )
      " {\"filter\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Instant\"}}} "
  -- Sutured Ghoul's "any number" and Dermotaxi's "a graveyard".
  Spec.it s "MkExileFromGraveyard, any number out of any graveyard" $
    Common.assertCodec
      s
      ExileFromGraveyard.codec
      ( ExileFromGraveyard.MkExileFromGraveyard
          { ExileFromGraveyard.filter = Filter.HasCardType CardType.Creature,
            ExileFromGraveyard.players = PlayerScope.Related PlayerRelation.AnyPlayer,
            ExileFromGraveyard.count = HowMany.UpTo Nothing,
            ExileFromGraveyard.orGraveyard = False,
            ExileFromGraveyard.kinds = [],
            ExileFromGraveyard.each = Quantity.Literal 1
          }
      )
      " {\"count\":{\"type\":\"UpTo\"},\"filter\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},\"players\":{\"type\":\"AnyPlayer\"}} "
  -- Frankenstein's Monster: exactly X, a graveyard fallback, and a choice of
  -- three counter kinds per card.
  Spec.it s "MkExileFromGraveyard, exactly X with a fallback and a counter per card" $
    Common.assertCodec
      s
      ExileFromGraveyard.codec
      ( ExileFromGraveyard.MkExileFromGraveyard
          { ExileFromGraveyard.filter = Filter.HasCardType CardType.Creature,
            ExileFromGraveyard.players = PlayerScope.Related PlayerRelation.You,
            ExileFromGraveyard.count = HowMany.Exactly (Quantity.InSlot (SlotName.MkSlotName (Text.pack "X"))),
            ExileFromGraveyard.orGraveyard = True,
            ExileFromGraveyard.kinds = [CounterKind.powerToughness 2 0, CounterKind.PlusOnePlusOne, CounterKind.powerToughness 0 2],
            ExileFromGraveyard.each = Quantity.Literal 1
          }
      )
      " {\"count\":{\"type\":\"Exactly\",\"value\":{\"type\":\"InSlot\",\"value\":\"X\"}},\"filter\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},\"kinds\":[{\"type\":\"PowerToughness\",\"value\":[2,0]},{\"type\":\"PlusOnePlusOne\"},{\"type\":\"PowerToughness\",\"value\":[0,2]}],\"orGraveyard\":true} "
  Spec.it s "has a schema" $ Common.assertHasSchema s ExileFromGraveyard.codec
