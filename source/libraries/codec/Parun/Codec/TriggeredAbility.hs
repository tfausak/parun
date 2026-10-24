{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.TriggeredAbility where

import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.Typeable as Typeable
import qualified Parun.Codec.AbilityName as AbilityNameCodec
import qualified Parun.Codec.Condition as Condition
import qualified Parun.Codec.Modal as Modal
import qualified Parun.Codec.TriggerCondition as TriggerCondition
import qualified Parun.Codec.TriggerLimit as TriggerLimit
import qualified Parun.Codec.Zone as Zone
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.AbilityName as AbilityName
import qualified Parun.Types.TriggerLimit as TriggerLimit
import qualified Parun.Types.TriggeredAbility as TriggeredAbility

-- | The wire format is unchanged by the conversion to a bundle; what it adds is
-- the schema.
codec :: (Typeable.Typeable card, Eq card, Typeable.Typeable ability, Eq ability) => Codec.Codec card -> Codec.Codec ability -> Codec.Codec (TriggeredAbility.TriggeredAbility card ability)
codec cardCodec abilityCodec = Fields.object $ do
  condition <- Fields.required "condition" TriggerCondition.codec TriggeredAbility.condition
  modal <- Fields.required "modal" (Modal.codec cardCodec abilityCodec) TriggeredAbility.modal
  intervening <- Fields.defaulted "intervening" Nothing (Common.maybe Condition.codec) TriggeredAbility.intervening
  name <- Fields.defaulted "name" Nothing (Common.maybe AbilityNameCodec.codec) TriggeredAbility.name
  limit <- Fields.defaulted "limit" TriggerLimit.Unlimited TriggerLimit.codec TriggeredAbility.limit
  functionsFrom <- Fields.defaulted "functionsFrom" Set.empty (Common.set Zone.codec) TriggeredAbility.functionsFrom
  pure
    TriggeredAbility.MkTriggeredAbility
      { TriggeredAbility.condition = condition,
        TriggeredAbility.modal = modal,
        TriggeredAbility.intervening = intervening,
        TriggeredAbility.name = name,
        TriggeredAbility.limit = limit,
        TriggeredAbility.functionsFrom = functionsFrom
      }

-- | A name-keyed map as a JSON OBJECT keyed by the ability name.
codecDelayed ::
  (Typeable.Typeable card, Eq card, Typeable.Typeable ability, Eq ability) =>
  Codec.Codec card ->
  Codec.Codec ability ->
  Codec.Codec (Map.Map AbilityName.AbilityName (TriggeredAbility.TriggeredAbility card ability))
codecDelayed cardCodec abilityCodec = Common.textMap AbilityName.unwrap (Right . AbilityName.MkAbilityName) (codec cardCodec abilityCodec)
