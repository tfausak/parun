module Parun.Codec.WithCounters where

import qualified Parun.Codec.EntryRiders as EntryRiders
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.WithCounters as WithCounters

-- | An array of kind/count pairs ascending by kind, which is EntryRiders'
-- counter spelling reused rather than re-spelled: the two payloads say the same
-- thing about the same rule (CR 614.1c and CR 122.6), so one wire form serves
-- both. It replaced the single @{"kind":...,"amount":...}@ object when the row
-- grew to several kinds (#2314), which itself replaced a two-element array
-- (#1464).
--
-- 'Common.nonEmptyKeyedList' and not 'Common.keyedList': an empty array would be
-- a row that places nothing, which no card prints.
codec :: Codec.Codec WithCounters.WithCounters
codec =
  Common.wrapper (Common.nonEmptyKeyedList EntryRiders.counter) WithCounters.MkWithCounters WithCounters.counters
