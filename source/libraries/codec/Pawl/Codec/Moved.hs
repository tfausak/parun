{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.Moved where

import qualified Data.Sequence as Seq
import qualified Pawl.Codec.ObjectId as ObjectId
import qualified Pawl.Codec.PlayerId as PlayerId
import qualified Pawl.Codec.ProjectedCharacteristics as ProjectedCharacteristics
import qualified Pawl.Codec.ZoneChange as ZoneChange
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.Moved as Moved

-- | A bare object keyed by the record's field names, replacing the two-element
-- array this payload used to be. Runtime-only: GameEvent serialises transcripts,
-- never card data.
codec :: Codec.Codec Moved.Moved
codec = Fields.object $ do
  change <- Fields.required "change" ZoneChange.codec Moved.change
  characteristics <- Fields.required "characteristics" ProjectedCharacteristics.codec Moved.characteristics
  otherArrivals <- Fields.required "otherArrivals" (Common.seq ObjectId.codec) Moved.otherArrivals
  -- Defaulted for the flag's reason below: a meld's entry is the only move that
  -- fills it.
  otherDepartures <- Fields.defaulted "otherDepartures" Seq.empty (Common.seq ObjectId.codec) Moved.otherDepartures
  -- Defaulted rather than required, CR 608.2n's move being the only one that
  -- sets it: an ordinary move's transcript keeps the shape it had.
  duringResolution <- Fields.defaulted "duringResolution" False Common.boolean Moved.duringResolution
  -- Defaulted for the same reason: only a revealed card leaving a hidden zone
  -- sets it.
  revealed <- Fields.defaulted "revealed" False Common.boolean Moved.revealed
  -- Defaulted for the same reason: a move into a hidden zone or face down
  -- leaves it unset.
  seenArriving <- Fields.defaulted "seenArriving" False Common.boolean Moved.seenArriving
  -- Defaulted for the same reason: only a move an effect made sets it.
  causedBy <- Fields.defaulted "causedBy" Nothing (Common.maybe PlayerId.codec) Moved.causedBy
  pure
    Moved.MkMoved
      { Moved.change = change,
        Moved.characteristics = characteristics,
        Moved.otherArrivals = otherArrivals,
        Moved.otherDepartures = otherDepartures,
        Moved.duringResolution = duringResolution,
        Moved.revealed = revealed,
        Moved.seenArriving = seenArriving,
        Moved.causedBy = causedBy
      }
