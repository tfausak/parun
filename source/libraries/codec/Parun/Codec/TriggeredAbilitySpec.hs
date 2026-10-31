module Parun.Codec.TriggeredAbilitySpec where

import qualified Data.Map.Strict as Map
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Parun.Codec.TriggeredAbility as TriggeredAbility
import qualified Parun.Json.Value as Value
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AbilityName as AbilityName
import qualified Parun.Types.Aggregation as Aggregation
import qualified Parun.Types.BeginningStep as BeginningStep
import qualified Parun.Types.BlockRole as BlockRole
import qualified Parun.Types.Clause as Clause
import qualified Parun.Types.CombatStep as CombatStep
import qualified Parun.Types.Compares as Compares
import qualified Parun.Types.Comparison as Comparison
import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.Count as Count
import qualified Parun.Types.Create as Create
import qualified Parun.Types.DamagePart as DamagePart
import qualified Parun.Types.DealDamage as DealDamage
import qualified Parun.Types.Effect as Effect
import qualified Parun.Types.EndingStep as EndingStep
import qualified Parun.Types.EntryRiders as EntryRiders
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.InZone as InZone
import qualified Parun.Types.Modal as Modal
import qualified Parun.Types.Mode as Mode
import qualified Parun.Types.ModeMemory as ModeMemory
import qualified Parun.Types.ModeSelection as ModeSelection
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.Optionality as Optionality
import qualified Parun.Types.Phase as Phase
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SacrificeEffect as SacrificeEffect
import qualified Parun.Types.Sacrificer as Sacrificer
import qualified Parun.Types.Scope as Scope
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.StepBegins as StepBegins
import qualified Parun.Types.Subtype as Subtype
import qualified Parun.Types.TriggerCondition as TriggerCondition
import qualified Parun.Types.TriggerLimit as TriggerLimit
import qualified Parun.Types.TriggeredAbility as TriggeredAbility
import qualified Parun.Types.TurnScope as TurnScope
import qualified Parun.Types.Zone as Zone

-- | The `card` parameter is instantiated at 'Text.Text' throughout.
-- 'TriggeredAbility.codec' reach it only through
-- the supplied Modal codec, so any type proves the shape.
cardCodec :: Codec.Codec Text.Text
cardCodec = Common.text

-- | And the `ability` parameter likewise: it too is reached only through the
-- codec supplied here, so any type proves the shape.
abilityCodec :: Codec.Codec Text.Text
abilityCodec = Common.text

codec :: Codec.Codec (TriggeredAbility.TriggeredAbility Text.Text Text.Text)
codec = TriggeredAbility.codec cardCodec abilityCodec

toJson :: TriggeredAbility.TriggeredAbility Text.Text Text.Text -> Value.Value
toJson = Codec.encode codec

fromJson :: Value.Value -> Either Text.Text (TriggeredAbility.TriggeredAbility Text.Text Text.Text)
fromJson = Codec.decode codec

-- One constructor, so three cases: both states of CR 603.4's `intervening`
-- field, and every field left at its default.
spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.TriggeredAbility" $ do
  Spec.it s "MkTriggeredAbility, Sarcomancy's zombie-token trigger (no intervening if)" $
    Common.assertJsonCodec
      s
      toJson
      fromJson
      ( TriggeredAbility.MkTriggeredAbility
          { TriggeredAbility.condition = TriggerCondition.SelfEnters,
            TriggeredAbility.modal =
              Modal.MkModal
                (Seq.singleton (Mode.MkMode (Seq.singleton (Clause.MkClause Nothing Nothing Nothing Optionality.Mandatory Nothing (Seq.singleton (Effect.Create (Create.MkCreate (Quantity.Literal 1) (Text.pack "Zombie Token") EntryRiders.defaultValue Nothing (PlayerRef.Relative PlayerRelation.You)))))) Map.empty))
                (ModeSelection.ChooseExactly 1)
                ModeMemory.NoMemory,
            TriggeredAbility.intervening = Nothing,
            TriggeredAbility.name = Nothing,
            TriggeredAbility.limit = TriggerLimit.Unlimited,
            TriggeredAbility.functionsFrom = Set.empty
          }
      )
      " {\"condition\":{\"type\":\"SelfEnters\"},\"modal\":{\"modes\":[{\"clauses\":[{\"effects\":[{\"type\":\"Create\",\"value\":{\"quantity\":{\"type\":\"Literal\",\"value\":1},\"card\":\"Zombie Token\"}}]}]}]}} "
  -- CR 603.4's intervening "if" clause is emitted only when the ability states
  -- one, so this case writes the key and the one above omits it.
  Spec.it s "MkTriggeredAbility, Sarcomancy's upkeep trigger (an intervening if)" $
    Common.assertJsonCodec
      s
      toJson
      fromJson
      ( TriggeredAbility.MkTriggeredAbility
          { TriggeredAbility.condition = TriggerCondition.StepBegins (StepBegins.MkStepBegins (Phase.Beginning BeginningStep.Upkeep) Nothing TurnScope.ControllersTurn),
            TriggeredAbility.modal =
              Modal.MkModal
                (Seq.singleton (Mode.MkMode (Seq.singleton (Clause.MkClause Nothing Nothing Nothing Optionality.Mandatory Nothing (Seq.singleton (Effect.DealDamage (DealDamage.MkDealDamage (Seq.singleton (DamagePart.MkDamagePart (ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "you"))) (Quantity.Literal 1))) Nothing Nothing Nothing Nothing))))) Map.empty))
                (ModeSelection.ChooseExactly 1)
                ModeMemory.NoMemory,
            TriggeredAbility.intervening =
              Just
                ( Condition.Compares
                    ( Compares.MkCompares
                        (Quantity.Count (Count.MkCount (Scope.InZone (InZone.MkInZone Zone.Battlefield (PlayerRef.Relative PlayerRelation.AnyPlayer))) (Filter.HasSubtype Subtype.Zombie) Aggregation.Members))
                        Comparison.Exactly
                        (Quantity.Literal 0)
                    )
                ),
            TriggeredAbility.name = Nothing,
            TriggeredAbility.limit = TriggerLimit.Unlimited,
            TriggeredAbility.functionsFrom = Set.empty
          }
      )
      " {\"condition\":{\"type\":\"StepBegins\",\"value\":{\"phase\":{\"type\":\"Beginning\",\"value\":{\"type\":\"Upkeep\"}},\"scope\":{\"type\":\"ControllersTurn\"}}},\"modal\":{\"modes\":[{\"clauses\":[{\"effects\":[{\"type\":\"DealDamage\",\"value\":{\"parts\":[{\"ref\":{\"type\":\"InSlot\",\"value\":\"you\"},\"quantity\":{\"type\":\"Literal\",\"value\":1}}]}}]}]}]},\"intervening\":{\"type\":\"Compares\",\"value\":{\"measured\":{\"type\":\"Count\",\"value\":{\"scope\":{\"type\":\"InZone\",\"value\":{\"zone\":{\"type\":\"Battlefield\"},\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"AnyPlayer\"}}}},\"filter\":{\"type\":\"HasSubtype\",\"value\":{\"type\":\"Zombie\"}},\"aggregation\":{\"type\":\"Members\"}}},\"comparison\":{\"type\":\"Exactly\"},\"threshold\":{\"type\":\"Literal\",\"value\":0}}}} "
  -- CR 603.7: Face.delayedAbilities is a name-keyed map, rendered as a JSON
  -- OBJECT keyed by the name in ascending order. The two entries are inserted in
  -- DESCENDING name order, so a trip that emitted the map's incidental traversal
  -- order rather than Map.toAscList fails this case.
  Spec.it s "toJsonDelayed/fromJsonDelayed sorts by name (Full Throttle, Tidal Wave)" $
    Common.assertJsonCodec
      s
      (Codec.encode (TriggeredAbility.codecDelayed cardCodec abilityCodec))
      (Codec.decode (TriggeredAbility.codecDelayed cardCodec abilityCodec))
      ( Map.fromList
          [ ( AbilityName.MkAbilityName (Text.pack "sacrifice it"),
              TriggeredAbility.MkTriggeredAbility
                { TriggeredAbility.condition = TriggerCondition.StepBegins (StepBegins.MkStepBegins (Phase.Ending EndingStep.EndStep) Nothing TurnScope.EachTurn),
                  TriggeredAbility.modal =
                    Modal.MkModal
                      (Seq.singleton (Mode.MkMode (Seq.singleton (Clause.MkClause Nothing Nothing Nothing Optionality.Mandatory Nothing (Seq.singleton (Effect.Sacrifice SacrificeEffect.MkSacrificeEffect {SacrificeEffect.ref = ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "token")), SacrificeEffect.sacrificer = Sacrificer.EffectController, SacrificeEffect.sacrificed = Nothing})))) Map.empty))
                      (ModeSelection.ChooseExactly 1)
                      ModeMemory.NoMemory,
                  TriggeredAbility.intervening = Nothing,
                  TriggeredAbility.name = Nothing,
                  TriggeredAbility.limit = TriggerLimit.Unlimited,
                  TriggeredAbility.functionsFrom = Set.empty
                }
            ),
            ( AbilityName.MkAbilityName (Text.pack "each combat"),
              TriggeredAbility.MkTriggeredAbility
                { TriggeredAbility.condition = TriggerCondition.StepBegins (StepBegins.MkStepBegins (Phase.Combat CombatStep.BeginningOfCombat) Nothing TurnScope.EachTurn),
                  TriggeredAbility.modal =
                    Modal.MkModal
                      (Seq.singleton (Mode.MkMode (Seq.singleton (Clause.MkClause Nothing Nothing Nothing Optionality.Mandatory Nothing (Seq.singleton (Effect.Untap (ObjectRef.EachMatching (Filter.DeclaredThisTurn BlockRole.Attacker)))))) Map.empty))
                      (ModeSelection.ChooseExactly 1)
                      ModeMemory.NoMemory,
                  TriggeredAbility.intervening = Nothing,
                  TriggeredAbility.name = Nothing,
                  TriggeredAbility.limit = TriggerLimit.Unlimited,
                  TriggeredAbility.functionsFrom = Set.empty
                }
            )
          ]
      )
      " {\"each combat\":{\"condition\":{\"type\":\"StepBegins\",\"value\":{\"phase\":{\"type\":\"Combat\",\"value\":{\"type\":\"BeginningOfCombat\"}},\"scope\":{\"type\":\"EachTurn\"}}},\"modal\":{\"modes\":[{\"clauses\":[{\"effects\":[{\"type\":\"Untap\",\"value\":{\"type\":\"EachMatching\",\"value\":{\"type\":\"DeclaredThisTurn\",\"value\":{\"type\":\"Attacker\"}}}}]}]}]}},\"sacrifice it\":{\"condition\":{\"type\":\"StepBegins\",\"value\":{\"phase\":{\"type\":\"Ending\",\"value\":{\"type\":\"EndStep\"}},\"scope\":{\"type\":\"EachTurn\"}}},\"modal\":{\"modes\":[{\"clauses\":[{\"effects\":[{\"type\":\"Sacrifice\",\"value\":{\"ref\":{\"type\":\"InSlot\",\"value\":\"token\"}}}]}]}]}}} "
  -- CR 603.4: an ability stating no intervening "if" leaves only the two
  -- required keys.
  Spec.it s "an all-default value omits every optional key" $
    Common.assertJsonCodec
      s
      toJson
      fromJson
      TriggeredAbility.MkTriggeredAbility
        { TriggeredAbility.condition = TriggerCondition.SelfEnters,
          TriggeredAbility.modal =
            Modal.MkModal
              (Seq.singleton (Mode.MkMode Seq.empty Map.empty))
              (ModeSelection.ChooseExactly 1)
              ModeMemory.NoMemory,
          TriggeredAbility.intervening = Nothing,
          TriggeredAbility.name = Nothing,
          TriggeredAbility.limit = TriggerLimit.Unlimited,
          TriggeredAbility.functionsFrom = Set.empty
        }
      " {\"condition\":{\"type\":\"SelfEnters\"},\"modal\":{\"modes\":[{}]}} "
  -- CR 613.1f: the name a LoseNamedAbility removal joins to.
  Spec.it s "a named ability carries its name" $
    Common.assertJsonCodec
      s
      toJson
      fromJson
      TriggeredAbility.MkTriggeredAbility
        { TriggeredAbility.condition = TriggerCondition.SelfEnters,
          TriggeredAbility.modal =
            Modal.MkModal
              (Seq.singleton (Mode.MkMode Seq.empty Map.empty))
              (ModeSelection.ChooseExactly 1)
              ModeMemory.NoMemory,
          TriggeredAbility.intervening = Nothing,
          TriggeredAbility.name = Just (AbilityName.MkAbilityName (Text.pack "vigil")),
          TriggeredAbility.limit = TriggerLimit.Unlimited,
          TriggeredAbility.functionsFrom = Set.empty
        }
      " {\"condition\":{\"type\":\"SelfEnters\"},\"modal\":{\"modes\":[{}]},\"name\":\"vigil\"} "
  -- CR 113.6b: the zones an ability states it functions in.
  Spec.it s "an ability stating its zones carries them" $
    Common.assertJsonCodec
      s
      toJson
      fromJson
      TriggeredAbility.MkTriggeredAbility
        { TriggeredAbility.condition = TriggerCondition.SelfEnters,
          TriggeredAbility.modal =
            Modal.MkModal
              (Seq.singleton (Mode.MkMode Seq.empty Map.empty))
              (ModeSelection.ChooseExactly 1)
              ModeMemory.NoMemory,
          TriggeredAbility.intervening = Nothing,
          TriggeredAbility.name = Nothing,
          TriggeredAbility.limit = TriggerLimit.Unlimited,
          TriggeredAbility.functionsFrom = Set.fromList [Zone.Library, Zone.Hand]
        }
      " {\"condition\":{\"type\":\"SelfEnters\"},\"functionsFrom\":[{\"type\":\"Library\"},{\"type\":\"Hand\"}],\"modal\":{\"modes\":[{}]}} "
