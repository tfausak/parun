module Parun.Codec.ActivePlayerEffectSpec where

import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Parun.Codec.ActivePlayerEffect as ActivePlayerEffect
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AbilityName as AbilityName
import qualified Parun.Types.ActivePlayerEffect as ActivePlayerEffect
import qualified Parun.Types.AffectedPlayers as AffectedPlayers
import qualified Parun.Types.CardName as CardName
import qualified Parun.Types.Expiry as Expiry
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerEffect as PlayerEffect
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.PlayerScope as PlayerScope
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.SourceChoices as SourceChoices
import qualified Parun.Types.Timestamp as Timestamp

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ActivePlayerEffect" $ do
  -- CR 611.1 / 613.11, Silence's row: the controller is STORED because the
  -- source is an instant already in a graveyard, so CR 109.5's "your opponents"
  -- has nothing live to resolve against. Its seat differs from every other
  -- number here.
  Spec.it s "a scoped effect that ends at cleanup" $
    Common.assertCodec
      s
      ActivePlayerEffect.codec
      ActivePlayerEffect.MkActivePlayerEffect
        { ActivePlayerEffect.source = ObjectId.MkObjectId 1,
          ActivePlayerEffect.controller = PlayerId.MkPlayerId 2,
          ActivePlayerEffect.choices = SourceChoices.MkSourceChoices {SourceChoices.names = Map.empty, SourceChoices.colors = Set.empty, SourceChoices.subtype = Nothing},
          ActivePlayerEffect.timestamp = Timestamp.MkTimestamp 3,
          ActivePlayerEffect.expiry = Expiry.AtCleanup,
          ActivePlayerEffect.scope = AffectedPlayers.Scoped (PlayerScope.Related PlayerRelation.Opponent),
          ActivePlayerEffect.effect = PlayerEffect.CantCastSpells,
          ActivePlayerEffect.ability = Nothing,
          ActivePlayerEffect.slots = Map.empty
        }
      " {\"source\":1,\"controller\":2,\"choices\":{},\"timestamp\":3,\"expiry\":{\"type\":\"AtCleanup\"},\"scope\":{\"type\":\"Scoped\",\"value\":{\"type\":\"Opponent\"}},\"effect\":{\"type\":\"CantCastSpells\"}} "
  -- The Named arm, which is the half no printed carrier has: the seat CR 601.2c
  -- chose, baked as the effect began. It differs from `controller`, so an
  -- encoder writing the controller into both fields could not pass.
  Spec.it s "an effect baked onto the seat its slot named" $
    Common.assertCodec
      s
      ActivePlayerEffect.codec
      ActivePlayerEffect.MkActivePlayerEffect
        { ActivePlayerEffect.source = ObjectId.MkObjectId 5,
          ActivePlayerEffect.controller = PlayerId.MkPlayerId 6,
          ActivePlayerEffect.choices = SourceChoices.MkSourceChoices {SourceChoices.names = Map.empty, SourceChoices.colors = Set.empty, SourceChoices.subtype = Nothing},
          ActivePlayerEffect.timestamp = Timestamp.MkTimestamp 7,
          ActivePlayerEffect.expiry = Expiry.Never,
          ActivePlayerEffect.scope = AffectedPlayers.Named (PlayerId.MkPlayerId 8),
          ActivePlayerEffect.effect = PlayerEffect.NoMaximumHandSize,
          ActivePlayerEffect.ability = Nothing,
          ActivePlayerEffect.slots = Map.empty
        }
      " {\"source\":5,\"controller\":6,\"choices\":{},\"timestamp\":7,\"expiry\":{\"type\":\"Never\"},\"scope\":{\"type\":\"Named\",\"value\":8},\"effect\":{\"type\":\"NoMaximumHandSize\"}} "
  -- CR 608.2h: the names baked as the effect began, Cheering Fanatic's row,
  -- and CR 607.5's pairing name, an acquired ability's.
  Spec.it s "an effect carrying the names its source had chosen" $
    Common.assertCodec
      s
      ActivePlayerEffect.codec
      ActivePlayerEffect.MkActivePlayerEffect
        { ActivePlayerEffect.source = ObjectId.MkObjectId 9,
          ActivePlayerEffect.controller = PlayerId.MkPlayerId 10,
          ActivePlayerEffect.choices = SourceChoices.MkSourceChoices {SourceChoices.names = Map.singleton (PlayerId.MkPlayerId 12) (CardName.MkCardName (Text.pack "Shock")), SourceChoices.colors = Set.empty, SourceChoices.subtype = Nothing},
          ActivePlayerEffect.timestamp = Timestamp.MkTimestamp 11,
          ActivePlayerEffect.expiry = Expiry.AtCleanup,
          ActivePlayerEffect.scope = AffectedPlayers.Scoped (PlayerScope.Related PlayerRelation.AnyPlayer),
          ActivePlayerEffect.effect = PlayerEffect.CantCastSpells,
          ActivePlayerEffect.ability = Just (AbilityName.MkAbilityName (Text.pack "thatExiledCard13")),
          ActivePlayerEffect.slots = Map.empty
        }
      " {\"source\":9,\"controller\":10,\"choices\":{\"names\":{\"12\":\"Shock\"}},\"timestamp\":11,\"expiry\":{\"type\":\"AtCleanup\"},\"scope\":{\"type\":\"Scoped\",\"value\":{\"type\":\"AnyPlayer\"}},\"effect\":{\"type\":\"CantCastSpells\"},\"ability\":\"thatExiledCard13\"} "
  -- CR 611.2a: the slot Parun.Engine.Cast.bindUser bound, Savage Summoning's
  -- "that spell can't be countered".
  Spec.it s "an effect carrying the spell its slot was bound to" $
    Common.assertCodec
      s
      ActivePlayerEffect.codec
      ActivePlayerEffect.MkActivePlayerEffect
        { ActivePlayerEffect.source = ObjectId.MkObjectId 14,
          ActivePlayerEffect.controller = PlayerId.MkPlayerId 15,
          ActivePlayerEffect.choices = SourceChoices.MkSourceChoices {SourceChoices.names = Map.empty, SourceChoices.colors = Set.empty, SourceChoices.subtype = Nothing},
          ActivePlayerEffect.timestamp = Timestamp.MkTimestamp 16,
          ActivePlayerEffect.expiry = Expiry.AtCleanup,
          ActivePlayerEffect.scope = AffectedPlayers.Scoped (PlayerScope.Related PlayerRelation.AnyPlayer),
          ActivePlayerEffect.effect = PlayerEffect.CantCastSpells,
          ActivePlayerEffect.ability = Nothing,
          ActivePlayerEffect.slots = Map.singleton (SlotName.MkSlotName (Text.pack "nextSpell")) (Set.singleton (ObjectId.MkObjectId 17))
        }
      " {\"source\":14,\"controller\":15,\"choices\":{},\"timestamp\":16,\"expiry\":{\"type\":\"AtCleanup\"},\"scope\":{\"type\":\"Scoped\",\"value\":{\"type\":\"AnyPlayer\"}},\"effect\":{\"type\":\"CantCastSpells\"},\"slots\":{\"nextSpell\":[17]}} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s ActivePlayerEffect.codec
