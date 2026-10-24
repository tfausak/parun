{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.CastFrom where

import qualified Parun.Codec.InZone as InZone
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.CastFrom as CastFrom
import qualified Parun.Types.PlayerRef as PlayerRef.Type
import qualified Parun.Types.PlayerRelation as PlayerRelation

-- | A bare object keyed by the record's field names, with the caster defaulted.
--
-- CR 109.5's "you" is the default because every printed clause of this family
-- either names it (Archfiend's Vessel, Breathless Knight) or is agentless, and
-- an agentless clause says @Relative AnyPlayer@ out loud rather than eliding it. The
-- ZONE is required: nothing about "was cast" implies a zone to have been cast
-- from.
codec :: Codec.Codec CastFrom.CastFrom
codec = Fields.object $ do
  caster <- Fields.defaulted "caster" (PlayerRef.Type.Relative PlayerRelation.You) PlayerRef.codec CastFrom.caster
  from <- Fields.required "from" InZone.codec CastFrom.from
  pure CastFrom.MkCastFrom {CastFrom.caster = caster, CastFrom.from = from}
