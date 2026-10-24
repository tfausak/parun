{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.TriggeredAbilitySource where

import qualified Data.Map.Strict as Map
import qualified Parun.Codec.Acquisition as Acquisition
import qualified Parun.Codec.Card as Card
import qualified Parun.Codec.GrantedAbility as GrantedAbility
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.Timestamp as Timestamp
import qualified Parun.Codec.TriggeredAbility as TriggeredAbility
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Acquisition as Acquisition.Type
import qualified Parun.Types.TriggeredAbilitySource as TriggeredAbilitySource

-- | The ability codec is built from the card codec the same way every other
-- parameterized codec in this library is.
codec :: Codec.Codec TriggeredAbilitySource.TriggeredAbilitySource
codec = Fields.object $ do
  source <- Fields.required "source" ObjectId.codec TriggeredAbilitySource.source
  ability <- Fields.required "ability" (TriggeredAbility.codec Card.codec (GrantedAbility.codec Card.codec)) TriggeredAbilitySource.ability
  -- CR 603.7a: absent for an ability the source itself has, which is every
  -- trigger but a delayed one.
  createdAt <- Fields.defaulted "createdAt" Nothing (Common.maybe Timestamp.codec) TriggeredAbilitySource.createdAt
  delayed <- Fields.defaulted "delayed" Map.empty (TriggeredAbility.codecDelayed Card.codec (GrantedAbility.codec Card.codec)) TriggeredAbilitySource.delayed
  acquisition <- Fields.defaulted "acquisition" Acquisition.Type.Own Acquisition.codec TriggeredAbilitySource.acquisition
  pure
    TriggeredAbilitySource.MkTriggeredAbilitySource
      { TriggeredAbilitySource.source = source,
        TriggeredAbilitySource.ability = ability,
        TriggeredAbilitySource.createdAt = createdAt,
        TriggeredAbilitySource.delayed = delayed,
        TriggeredAbilitySource.acquisition = acquisition
      }
