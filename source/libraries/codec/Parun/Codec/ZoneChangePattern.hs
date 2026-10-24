{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ZoneChangePattern where

import qualified Parun.Codec.ControllerRelation as ControllerRelation
import qualified Parun.Codec.DiscardCause as DiscardCause
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.Zone as Zone
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ControllerRelation as ControllerRelation
import qualified Parun.Types.DiscardCause as DiscardCause
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Zone as Zone
import qualified Parun.Types.ZoneChangePattern as ZoneChangePattern

-- | Saying what the object is -- CR 702.34a's "this card", Anafenza, the
-- Foremost's "a nontoken creature" -- is the marked case, so the trivial
-- predicate is what a pattern that says nothing about the object means.
defaultWhatObject :: Filter.Filter Keyword.Keyword
defaultWhatObject = Filter.And []

-- | CR 702.34a's "instead of putting it anywhere else" names no destination at
-- all, and every destination is the unrestricted reading, so it is what a
-- pattern that says nothing means.
defaultWhenDestination :: Maybe Zone.Zone
defaultWhenDestination = Nothing

-- | CR 109.5 reads a controller relation against the effect's source;
-- "anyone's" is the unrestricted reading, so it is what a pattern that says
-- nothing means.
defaultWhoseObject :: ControllerRelation.ControllerRelation
defaultWhoseObject = ControllerRelation.Related PlayerRelation.AnyPlayer

-- | Every move is admitted unless the card says it watches a discard, so no
-- cause is what a pattern that says nothing means.
defaultWhenDiscarded :: Maybe DiscardCause.DiscardCause
defaultWhenDiscarded = Nothing

codec :: Codec.Codec ZoneChangePattern.ZoneChangePattern
codec = Fields.object $ do
  whenDestination <- Fields.defaulted "whenDestination" defaultWhenDestination (Common.maybe Zone.codec) ZoneChangePattern.whenDestination
  whoseObject <- Fields.defaulted "whoseObject" defaultWhoseObject ControllerRelation.codec ZoneChangePattern.whoseObject
  whatObject <- Fields.defaulted "whatObject" defaultWhatObject (Filter.codec Keyword.codec) ZoneChangePattern.whatObject
  whenDiscarded <- Fields.defaulted "whenDiscarded" defaultWhenDiscarded (Common.maybe DiscardCause.codec) ZoneChangePattern.whenDiscarded
  duringResolution <- Fields.defaulted "duringResolution" False Common.boolean ZoneChangePattern.duringResolution
  pure
    ZoneChangePattern.MkZoneChangePattern
      { ZoneChangePattern.whenDestination = whenDestination,
        ZoneChangePattern.whoseObject = whoseObject,
        ZoneChangePattern.whatObject = whatObject,
        ZoneChangePattern.whenDiscarded = whenDiscarded,
        ZoneChangePattern.duringResolution = duringResolution
      }
