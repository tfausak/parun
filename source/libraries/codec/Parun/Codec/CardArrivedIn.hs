{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.CardArrivedIn where

import qualified Data.Set as Set
import qualified Parun.Codec.Zone as Zone
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.CardArrivedIn as CardArrivedIn

-- | A bare object keyed by the record's field names, as Parun.Codec.MovedBetween
-- is. `excluding` is defaulted rather than required because the empty set is CR
-- 712.21e's own reading -- "from anywhere" -- rather than a convenience.
codec :: Codec.Codec CardArrivedIn.CardArrivedIn
codec = Fields.object $ do
  to <- Fields.required "to" Zone.codec CardArrivedIn.to
  excluding <- Fields.defaulted "excluding" Set.empty (Common.set Zone.codec) CardArrivedIn.excluding
  pure CardArrivedIn.MkCardArrivedIn {CardArrivedIn.to = to, CardArrivedIn.excluding = excluding}
