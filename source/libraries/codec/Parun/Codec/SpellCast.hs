{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.SpellCast where

import qualified Parun.Codec.ActingPermanent as ActingPermanent
import qualified Parun.Codec.PhaseSelector as PhaseSelector
import qualified Parun.Codec.TurnScope as TurnScope
import qualified Parun.Codec.Zone as Zone
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.SpellCast as SpellCast

-- | A bare object keyed by the record's field names, replacing the two-element
-- array this payload used to be. The first two keys are required: a cast of
-- this spell and a cast of a matching one are different cards, and so are an
-- unscoped trigger and a scoped one, not defaulted ones. The zone and the ordinal are
-- elided instead, because a trigger that names neither is what almost every
-- printing writes, and the phase and the copy flag for the same reason.
codec :: Codec.Codec SpellCast.SpellCast
codec = Fields.object $ do
  spell <- Fields.required "spell" ActingPermanent.codec SpellCast.spell
  scope <- Fields.required "scope" TurnScope.codec SpellCast.scope
  zone <- Fields.defaulted "zone" Nothing (Common.maybe Zone.codec) SpellCast.zone
  ordinal <- Fields.defaulted "ordinal" Nothing (Common.maybe Common.natural) SpellCast.ordinal
  phase <- Fields.defaulted "phase" Nothing (Common.maybe PhaseSelector.codec) SpellCast.phase
  copies <- Fields.defaulted "copies" False Common.boolean SpellCast.copies
  pure SpellCast.MkSpellCast {SpellCast.spell = spell, SpellCast.scope = scope, SpellCast.zone = zone, SpellCast.ordinal = ordinal, SpellCast.phase = phase, SpellCast.copies = copies}
