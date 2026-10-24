{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ZoneChangeR where

import qualified Parun.Codec.LibraryPosition as LibraryPosition
import qualified Parun.Codec.Zone as Zone
import qualified Parun.Codec.ZoneChangePattern as ZoneChangePattern
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.LibraryPosition as LibraryPosition
import qualified Parun.Types.ZoneChangeR as ZoneChangeR

-- | A bare object keyed by the record's field names, replacing the two-element
-- array this payload used to be (#1464).
codec :: Codec.Codec ZoneChangeR.ZoneChangeR
codec = Fields.object $ do
  matching <- Fields.required "matching" ZoneChangePattern.codec ZoneChangeR.matching
  destination <- Fields.required "destination" Zone.codec ZoneChangeR.destination
  revealing <- Fields.defaulted "revealing" False Common.boolean ZoneChangeR.revealing
  shuffling <- Fields.defaulted "shuffling" False Common.boolean ZoneChangeR.shuffling
  position <- Fields.defaulted "position" LibraryPosition.defaultValue LibraryPosition.codec ZoneChangeR.position
  optional <- Fields.defaulted "optional" False Common.boolean ZoneChangeR.optional
  pure
    ZoneChangeR.MkZoneChangeR
      { ZoneChangeR.matching = matching,
        ZoneChangeR.destination = destination,
        ZoneChangeR.revealing = revealing,
        ZoneChangeR.shuffling = shuffling,
        ZoneChangeR.position = position,
        ZoneChangeR.optional = optional
      }
