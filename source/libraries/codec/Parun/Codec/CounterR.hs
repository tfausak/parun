{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.CounterR where

import qualified Parun.Codec.CounterPattern as CounterPattern
import qualified Parun.Codec.Scaling as Scaling
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.CounterR as CounterR

-- | A bare object keyed by the record's field names, replacing the two-element
-- array this payload used to be (#1464).
codec :: Codec.Codec CounterR.CounterR
codec = Fields.object $ do
  matching <- Fields.required "matching" CounterPattern.codec CounterR.matching
  scaling <- Fields.required "scaling" Scaling.codec CounterR.scaling
  pure
    CounterR.MkCounterR
      { CounterR.matching = matching,
        CounterR.scaling = scaling
      }
