{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.MovedBetween where

import qualified Parun.Codec.Zone as Zone
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.MovedBetween as MovedBetween

-- | A bare object keyed by the record's field names, replacing the two-element
-- array this payload used to be (#1464).
codec :: Codec.Codec MovedBetween.MovedBetween
codec = Fields.object $ do
  from <- Fields.required "from" Zone.codec MovedBetween.from
  to <- Fields.required "to" Zone.codec MovedBetween.to
  pure MovedBetween.MkMovedBetween {MovedBetween.from = from, MovedBetween.to = to}
