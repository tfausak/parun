{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.FloatingCandidate where

import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.Timestamp as Timestamp
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.FloatingCandidate as FloatingCandidate

codec :: Codec.Codec FloatingCandidate.FloatingCandidate
codec = Fields.object $ do
  source <- Fields.required "source" ObjectId.codec FloatingCandidate.source
  timestamp <- Fields.required "timestamp" Timestamp.codec FloatingCandidate.timestamp
  pure FloatingCandidate.MkFloatingCandidate {FloatingCandidate.source = source, FloatingCandidate.timestamp = timestamp}
