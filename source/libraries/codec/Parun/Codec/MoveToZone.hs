{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.MoveToZone where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.EntryRiders as EntryRiders
import qualified Parun.Codec.LibraryPlacement as LibraryPlacement
import qualified Parun.Codec.MoveDuration as MoveDuration
import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.Codec.Zone as Zone
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.EntryRiders as EntryRiders
import qualified Parun.Types.LibraryPlacement as LibraryPlacement
import qualified Parun.Types.MoveToZone as MoveToZone

-- | Five independently elided keys, each omitted when it is its default: the
-- riders (CR 110.5b), the bound slot, CR 113.6m's origin zone, CR 401.2's
-- library placement and CR 610.3's duration.
--
-- This is what retires @moveTail@. That function read a VARIABLE-LENGTH array
-- tail and recovered which element was which from each one's JSON type, in a
-- fixed order -- zone and placement first, because 'EntryRiders' would have
-- accepted either tagged object and silently returned the defaults. Named keys
-- need none of it: absence is absence, and two objects that are both objects no
-- longer have to be told apart.
codec :: (Typeable.Typeable ability, Eq ability) => Codec.Codec ability -> Codec.Codec (MoveToZone.MoveToZone ability)
codec abilityCodec = Fields.object $ do
  ref <- Fields.required "ref" ObjectRef.codec MoveToZone.ref
  zone <- Fields.required "zone" Zone.codec MoveToZone.zone
  riders <- Fields.defaulted "riders" EntryRiders.defaultValue (EntryRiders.codec abilityCodec) MoveToZone.riders
  slot <- Fields.defaulted "slot" Nothing (Common.maybe SlotName.codec) MoveToZone.slot
  origin <- Fields.defaulted "origin" Nothing (Common.maybe Zone.codec) MoveToZone.origin
  placement <- Fields.defaulted "placement" LibraryPlacement.defaultValue LibraryPlacement.codec MoveToZone.placement
  duration <- Fields.defaulted "duration" Nothing (Common.maybe MoveDuration.codec) MoveToZone.duration
  pure
    MoveToZone.MkMoveToZone
      { MoveToZone.ref = ref,
        MoveToZone.zone = zone,
        MoveToZone.riders = riders,
        MoveToZone.slot = slot,
        MoveToZone.origin = origin,
        MoveToZone.placement = placement,
        MoveToZone.duration = duration
      }
