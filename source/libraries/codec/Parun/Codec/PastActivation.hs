{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PastActivation where

import qualified Parun.Codec.AbilityKind as AbilityKind
import qualified Parun.Codec.ActivatedAbility as ActivatedAbility
import qualified Parun.Codec.Card as Card
import qualified Parun.Codec.GrantedAbility as GrantedAbility
import qualified Parun.Codec.ObjectSnapshot as ObjectSnapshot
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PastActivation as PastActivation

-- | A bare object keyed by the record's field names.
codec :: Codec.Codec PastActivation.PastActivation
codec = Fields.object $ do
  activator <- Fields.required "activator" PlayerId.codec PastActivation.activator
  source <- Fields.required "source" ObjectSnapshot.codec PastActivation.source
  ability <- Fields.required "ability" (Common.maybe (ActivatedAbility.codec Card.codec (GrantedAbility.codec Card.codec))) PastActivation.ability
  kind <- Fields.required "kind" AbilityKind.codec PastActivation.kind
  targets <- Fields.required "targets" (Common.list ObjectSnapshot.codec) PastActivation.targets
  pure
    PastActivation.MkPastActivation
      { PastActivation.activator = activator,
        PastActivation.source = source,
        PastActivation.ability = ability,
        PastActivation.kind = kind,
        PastActivation.targets = targets
      }
