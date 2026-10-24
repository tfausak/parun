{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.KeywordTally where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Scope as Scope
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.KeywordTally as KeywordTally

-- | A bare object keyed by the record's field names, Parun.Codec.Count's shape
-- less its aggregation. The keyword codec is a PARAMETER; see
-- Parun.Codec.Filter's header.
codec :: (Typeable.Typeable keyword, Eq keyword) => Codec.Codec keyword -> Codec.Codec (KeywordTally.KeywordTally keyword)
codec keywordCodec = Fields.object $ do
  scope <- Fields.required "scope" Scope.codec KeywordTally.scope
  filter_ <- Fields.required "filter" (Filter.codec keywordCodec) KeywordTally.filter
  pure KeywordTally.MkKeywordTally {KeywordTally.scope = scope, KeywordTally.filter = filter_}
