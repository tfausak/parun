{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.ChangeWord where

import qualified Pawl.Codec.TextWord as TextWord
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.ChangeWord as ChangeWord

-- | A bare object keyed by the record's field names, replacing the two-element
-- array this payload used to be (#1464).
codec :: Codec.Codec ChangeWord.ChangeWord
codec = Fields.object $ do
  from_ <- Fields.required "from" TextWord.codec ChangeWord.from
  to <- Fields.required "to" TextWord.codec ChangeWord.to
  pure
    ChangeWord.MkChangeWord
      { ChangeWord.from = from_,
        ChangeWord.to = to
      }
