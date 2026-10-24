{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ActivatedAbilitySource where

import qualified Data.Map.Strict as Map
import qualified Parun.Codec.Acquisition as Acquisition
import qualified Parun.Codec.ActivatedAbility as ActivatedAbility
import qualified Parun.Codec.Card as Card
import qualified Parun.Codec.GrantedAbility as GrantedAbility
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.TriggeredAbility as TriggeredAbility
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Acquisition as Acquisition.Type
import qualified Parun.Types.ActivatedAbilitySource as ActivatedAbilitySource

-- | The ability codec is built from the card codec the same way every other
-- parameterized codec in this library is.
codec :: Codec.Codec ActivatedAbilitySource.ActivatedAbilitySource
codec = Fields.object $ do
  source <- Fields.required "source" ObjectId.codec ActivatedAbilitySource.source
  ability <- Fields.required "ability" (ActivatedAbility.codec Card.codec (GrantedAbility.codec Card.codec)) ActivatedAbilitySource.ability
  delayed <- Fields.defaulted "delayed" Map.empty (TriggeredAbility.codecDelayed Card.codec (GrantedAbility.codec Card.codec)) ActivatedAbilitySource.delayed
  acquisition <- Fields.defaulted "acquisition" Acquisition.Type.Own Acquisition.codec ActivatedAbilitySource.acquisition
  pure
    ActivatedAbilitySource.MkActivatedAbilitySource
      { ActivatedAbilitySource.source = source,
        ActivatedAbilitySource.ability = ability,
        ActivatedAbilitySource.delayed = delayed,
        ActivatedAbilitySource.acquisition = acquisition
      }
