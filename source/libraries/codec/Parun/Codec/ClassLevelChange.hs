{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ClassLevelChange where

import qualified Parun.Codec.ClassLevel as ClassLevel
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ClassLevelChange as ClassLevelChange

-- | A bare object keyed by the record's field names, Parun.Codec.CounterChange's
-- shape. Runtime-only: GameEvent serialises transcripts, never card data.
codec :: Codec.Codec ClassLevelChange.ClassLevelChange
codec = Fields.object $ do
  object <- Fields.required "object" ObjectId.codec ClassLevelChange.object
  before <- Fields.required "before" ClassLevel.codec ClassLevelChange.before
  after <- Fields.required "after" ClassLevel.codec ClassLevelChange.after
  pure
    ClassLevelChange.MkClassLevelChange
      { ClassLevelChange.object = object,
        ClassLevelChange.before = before,
        ClassLevelChange.after = after
      }
