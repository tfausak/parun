{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.CountersFromPermanents where

import qualified Data.Text as Text
import qualified Data.Typeable as Typeable
import qualified Parun.Codec.CostAmount as CostAmount
import qualified Parun.Codec.CounterSpread as CounterSpread
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.WhichCounters as WhichCounters
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.CounterSpread as CounterSpread.Type
import qualified Parun.Types.CountersFromPermanents as CountersFromPermanents
import qualified Parun.Types.WhichCounters as WhichCounters.Type

-- | A bare object keyed by the record's field names, Parun.Codec.TapPermanents'
-- shape. The keyword codec is a PARAMETER; see Parun.Codec.Filter's header.
-- The spread is omitted at FromOne, the one-permanent form.
--
-- Counters of any kind are accepted only at a count the payer does not settle
-- (Tayam, Luminous Enigma; Soul Diviner): no printing removes "one or more
-- counters" of any kind ('Fields.objectWith''s check).
codec :: (Typeable.Typeable keyword, Eq keyword) => Codec.Codec keyword -> Codec.Codec (CountersFromPermanents.CountersFromPermanents keyword)
codec keywordCodec = Fields.objectWith check $ do
  count <- Fields.required "count" CostAmount.codec CountersFromPermanents.count
  kind <- Fields.required "kind" (WhichCounters.codec keywordCodec) CountersFromPermanents.kind
  whichPermanent <- Fields.required "whichPermanent" (Filter.codec keywordCodec) CountersFromPermanents.whichPermanent
  spread <- Fields.defaulted "spread" CounterSpread.Type.FromOne CounterSpread.codec CountersFromPermanents.spread
  pure CountersFromPermanents.MkCountersFromPermanents {CountersFromPermanents.count = count, CountersFromPermanents.kind = kind, CountersFromPermanents.whichPermanent = whichPermanent, CountersFromPermanents.spread = spread}
  where
    check removal = case (CountersFromPermanents.kind removal, CountersFromPermanents.spread removal) of
      (WhichCounters.Type.OfAnyKind, CounterSpread.Type.FromAmongAtLeast) -> Left (Text.pack "RemoveCounters: counters of any kind are removed only at a fixed count")
      _ -> Right removal
