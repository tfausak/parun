{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.HalfUnlocked where

import qualified Parun.Codec.CardName as CardName
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.HalfUnlocked as HalfUnlocked

-- | A bare object keyed by the record's field names, replacing the positional
-- array this payload used to be. Runtime-only: GameEvent serialises transcripts,
-- never card data.
codec :: Codec.Codec HalfUnlocked.HalfUnlocked
codec = Fields.object $ do
  object <- Fields.required "object" ObjectId.codec HalfUnlocked.object
  actor <- Fields.required "actor" PlayerId.codec HalfUnlocked.actor
  name <- Fields.required "name" CardName.codec HalfUnlocked.name
  fully <- Fields.required "fully" Common.boolean HalfUnlocked.fully
  pure
    HalfUnlocked.MkHalfUnlocked
      { HalfUnlocked.object = object,
        HalfUnlocked.actor = actor,
        HalfUnlocked.name = name,
        HalfUnlocked.fully = fully
      }
