{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.KeywordsAre where

import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.Reference as Reference
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.KeywordsAre as KeywordsAre

-- | The keyword is spelled as a card's JSON spells it.
codec :: Codec.Codec KeywordsAre.KeywordsAre
codec = Fields.object $ do
  object <- Fields.required "object" Reference.codec KeywordsAre.object
  keyword <- Fields.required "keyword" Keyword.codec KeywordsAre.keyword
  count <- Fields.required "count" Common.natural KeywordsAre.count
  pure KeywordsAre.MkKeywordsAre {KeywordsAre.object = object, KeywordsAre.keyword = keyword, KeywordsAre.count = count}
