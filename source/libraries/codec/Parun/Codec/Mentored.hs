{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Mentored where

import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Mentored as Mentored

-- | A bare object keyed by the record's field names, replacing the two-element
-- array this payload used to be. Runtime-only: GameEvent serialises transcripts,
-- never card data.
codec :: Codec.Codec Mentored.Mentored
codec = Fields.object $ do
  mentor <- Fields.required "mentor" ObjectId.codec Mentored.mentor
  mentored <- Fields.required "mentored" ObjectId.codec Mentored.mentored
  pure
    Mentored.MkMentored
      { Mentored.mentor = mentor,
        Mentored.mentored = mentored
      }
