{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Guess where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Guess as Guess

-- | A bare object keyed by the record's field names, every one required: no
-- printed guess leaves any of them to a default.
codec :: Codec.Codec Guess.Guess
codec = Fields.object $ do
  subject <- Fields.required "subject" ObjectRef.codec Guess.subject
  slot <- Fields.required "slot" SlotName.codec Guess.slot
  guesser <- Fields.required "guesser" PlayerRef.codec Guess.guesser
  proposition <- Fields.required "proposition" (Filter.codec Keyword.codec) Guess.proposition
  right <- Fields.required "right" SlotName.codec Guess.right
  pure
    Guess.MkGuess
      { Guess.subject = subject,
        Guess.slot = slot,
        Guess.guesser = guesser,
        Guess.proposition = proposition,
        Guess.right = right
      }
