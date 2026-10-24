{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ChangeWord where

import qualified Parun.Codec.TextWord as TextWord
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ChangeWord as ChangeWord

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
