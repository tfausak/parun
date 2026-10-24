{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.CastFromZone where

import qualified Parun.Codec.CostComponent as CostComponent
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.InZone as InZone
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.PermissionLimit as PermissionLimit
import qualified Parun.Codec.PermissionPool as PermissionPool
import qualified Parun.Codec.PermissionVerb as PermissionVerb
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.CastFromZone as CastFromZone
import qualified Parun.Types.PermissionLimit as PermissionLimit
import qualified Parun.Types.PermissionPool as PermissionPool
import qualified Parun.Types.PermissionVerb as PermissionVerb

-- | A bare object keyed by the record's field names. The zone reference is
-- Parun.Codec.InZone's, so CR 400.1's shared/per-player invariant is enforced here
-- too: a permission naming "the battlefield's owner" never decodes.
--
-- The limit DEFAULTS to Unlimited, which is the permission every card that
-- prints no budget grants (Future Sight, Garruk's Horde, Sen Triplets), and the
-- verb to Cast, which is what a permission naming no land play grants. The pool
-- defaults to the whole zone and the additional costs to none.
codec :: Codec.Codec CastFromZone.CastFromZone
codec = Fields.object $ do
  from <- Fields.required "from" InZone.codec CastFromZone.from
  matching <- Fields.required "matching" (Filter.codec Keyword.codec) CastFromZone.matching
  limit <- Fields.defaulted "limit" PermissionLimit.Unlimited PermissionLimit.codec CastFromZone.limit
  verb <- Fields.defaulted "verb" PermissionVerb.Cast PermissionVerb.codec CastFromZone.verb
  pool <- Fields.defaulted "pool" PermissionPool.EveryCard PermissionPool.codec CastFromZone.pool
  additionalCosts <- Fields.defaulted "additionalCosts" [] (Common.list (CostComponent.codec Keyword.codec)) CastFromZone.additionalCosts
  reduction <- Fields.defaulted "reduction" 0 Common.natural CastFromZone.reduction
  pure CastFromZone.MkCastFromZone {CastFromZone.from = from, CastFromZone.matching = matching, CastFromZone.limit = limit, CastFromZone.verb = verb, CastFromZone.pool = pool, CastFromZone.additionalCosts = additionalCosts, CastFromZone.reduction = reduction}
