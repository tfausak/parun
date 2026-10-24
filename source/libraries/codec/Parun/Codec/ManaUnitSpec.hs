module Parun.Codec.ManaUnitSpec where

import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Parun.Codec.FaceSpec as FaceSpec
import qualified Parun.Codec.ManaUnit as ManaUnit
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Color as Color
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.ManaRestriction as ManaRestriction
import qualified Parun.Types.ManaRetention as ManaRetention
import qualified Parun.Types.ManaType as ManaType
import qualified Parun.Types.ManaUnit as ManaUnit
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.ProductionTag as ProductionTag
import qualified Parun.Types.SourceChoices as SourceChoices
import qualified Parun.Types.SpendTrigger as SpendTrigger
import qualified Parun.Types.Subtype as Subtype

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ManaUnit" $ do
  -- The mana almost every source makes: no tag, CR 500.5's ordinary retention,
  -- and CR 106.6's restriction absent.
  Spec.it s "plain mana" $
    Common.assertCodec
      s
      ManaUnit.codec
      ManaUnit.MkManaUnit
        { ManaUnit.manaType = ManaType.Colorless,
          ManaUnit.tags = Set.empty,
          ManaUnit.retention = ManaRetention.Ordinary,
          ManaUnit.restriction = Nothing,
          ManaUnit.rider = Nothing,
          ManaUnit.spendTrigger = Nothing,
          ManaUnit.sourceChoices = Nothing,
          ManaUnit.sourceLastExiled = Nothing
        }
      " {\"manaType\":{\"type\":\"Colorless\"},\"tags\":[],\"retention\":{\"type\":\"Ordinary\"},\"restriction\":null,\"rider\":null,\"sourceChoices\":null} "
  -- Every axis but the rider at once, each away from its default: CR 107.4h's
  -- snow tag, CR 514.2's retention, Geosurge's "spend this mana only to cast"
  -- restriction, CR 607.2d's subtype baked off the source (Pillar of Origins)
  -- and CR 607.2a's last exiled card (Ice Cauldron).
  Spec.it s "snow mana kept until end of turn, spendable only on creature spells" $
    Common.assertCodec
      s
      ManaUnit.codec
      ManaUnit.MkManaUnit
        { ManaUnit.manaType = ManaType.Colored Color.Red,
          ManaUnit.tags = Set.singleton ProductionTag.Snow,
          ManaUnit.retention = ManaRetention.UntilEndOfTurn,
          ManaUnit.restriction = Just (ManaRestriction.onlyCasts (Filter.HasCardType CardType.Creature)),
          ManaUnit.rider = Nothing,
          ManaUnit.spendTrigger = Nothing,
          ManaUnit.sourceChoices = Just SourceChoices.MkSourceChoices {SourceChoices.names = Map.empty, SourceChoices.colors = Set.singleton Color.Red, SourceChoices.subtype = Just Subtype.Goblin},
          ManaUnit.sourceLastExiled = Just (ObjectId.MkObjectId 7)
        }
      " {\"manaType\":{\"type\":\"Colored\",\"value\":{\"type\":\"Red\"}},\"tags\":[{\"type\":\"Snow\"}],\"retention\":{\"type\":\"UntilEndOfTurn\"},\"restriction\":{\"casts\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}},\"rider\":null,\"sourceChoices\":{\"colors\":[{\"type\":\"Red\"}],\"subtype\":{\"type\":\"Goblin\"}},\"sourceLastExiled\":7} "
  -- Pyromancer's Goggles' red: CR 106.6's third shape, written only when set.
  Spec.it s "mana carrying a spend trigger" $
    Common.assertCodec
      s
      ManaUnit.codec
      ManaUnit.MkManaUnit
        { ManaUnit.manaType = ManaType.Colored Color.Red,
          ManaUnit.tags = Set.empty,
          ManaUnit.retention = ManaRetention.Ordinary,
          ManaUnit.restriction = Nothing,
          ManaUnit.rider = Nothing,
          ManaUnit.spendTrigger =
            Just
              SpendTrigger.MkSpendTrigger
                { SpendTrigger.casts = Filter.HasCardType CardType.Instant,
                  SpendTrigger.ability = FaceSpec.minimalTriggeredAbility,
                  SpendTrigger.source = ObjectId.MkObjectId 4,
                  SpendTrigger.controller = PlayerId.MkPlayerId 0
                },
          ManaUnit.sourceChoices = Nothing,
          ManaUnit.sourceLastExiled = Nothing
        }
      ( " {\"manaType\":{\"type\":\"Colored\",\"value\":{\"type\":\"Red\"}},\"tags\":[],\"retention\":{\"type\":\"Ordinary\"},\"restriction\":null,\"rider\":null,"
          <> "\"spendTrigger\":{\"casts\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Instant\"}},\"ability\":{\"condition\":{\"type\":\"SelfEnters\"},\"modal\":{\"modes\":[{}]}},\"source\":4,\"controller\":0},"
          <> "\"sourceChoices\":null} "
      )
  Spec.it s "has a schema" $
    Common.assertHasSchema s ManaUnit.codec
