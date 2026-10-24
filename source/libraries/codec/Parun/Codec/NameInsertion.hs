{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.NameInsertion where

import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.NameInsertion as NameInsertion

-- | A bare object keyed by the record's field names.
codec :: Codec.Codec NameInsertion.NameInsertion
codec = Fields.object $ do
  word <- Fields.required "word" Common.text NameInsertion.word
  after <- Fields.required "after" Common.natural NameInsertion.after
  pure NameInsertion.MkNameInsertion {NameInsertion.word = word, NameInsertion.after = after}
