{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.InherentTriggerSource where

import qualified Parun.Codec.Card as Card
import qualified Parun.Codec.GrantedAbility as GrantedAbility
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.Codec.TriggeredAbility as TriggeredAbility
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.InherentTriggerSource as InherentTriggerSource

-- | The key is `controller` rather than `source`, which is the whole of what
-- separates this from Parun.Codec.TriggeredAbilitySource: CR 725.2's inherent
-- trigger has no source object to name.
codec :: Codec.Codec InherentTriggerSource.InherentTriggerSource
codec = Fields.object $ do
  controller <- Fields.required "controller" PlayerId.codec InherentTriggerSource.controller
  ability <- Fields.required "ability" (TriggeredAbility.codec Card.codec (GrantedAbility.codec Card.codec)) InherentTriggerSource.ability
  pure
    InherentTriggerSource.MkInherentTriggerSource
      { InherentTriggerSource.controller = controller,
        InherentTriggerSource.ability = ability
      }
