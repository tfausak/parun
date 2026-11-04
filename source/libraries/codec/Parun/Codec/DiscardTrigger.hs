{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.DiscardTrigger where

import qualified Parun.Codec.Batching as Batching
import qualified Parun.Codec.DiscardSubject as DiscardSubject
import qualified Parun.Codec.DiscardWay as DiscardWay
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Batching as BatchingType
import qualified Parun.Types.DiscardTrigger as DiscardTrigger
import qualified Parun.Types.DiscardWay as DiscardWayType

-- | A bare object keyed by the record's field names. AnyDiscard and
-- EachOccurrence write no key.
codec :: Codec.Codec DiscardTrigger.DiscardTrigger
codec = Fields.object $ do
  subject <- Fields.required "subject" DiscardSubject.codec DiscardTrigger.subject
  way <- Fields.defaulted "way" DiscardWayType.AnyDiscard DiscardWay.codec DiscardTrigger.way
  batching <- Fields.defaulted "batching" BatchingType.EachOccurrence Batching.codec DiscardTrigger.batching
  pure
    DiscardTrigger.MkDiscardTrigger
      { DiscardTrigger.subject = subject,
        DiscardTrigger.way = way,
        DiscardTrigger.batching = batching
      }
