{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.KeywordRiderGrant where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.KeywordDesignator as KeywordDesignator
import qualified Parun.Codec.RiderClause as RiderClause
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.KeywordRiderGrant as KeywordRiderGrant

-- | A bare object keyed by the record's field names, as every other
-- Parun.Types.PlayerEffect payload is (#1464).
codec :: Codec.Codec KeywordRiderGrant.KeywordRiderGrant
codec = Fields.object $ do
  abilities <- Fields.required "abilities" (KeywordDesignator.codec Keyword.codec) KeywordRiderGrant.abilities
  relaxes <- Fields.required "relaxes" RiderClause.codec KeywordRiderGrant.relaxes
  permanents <- Fields.required "permanents" (Filter.codec Keyword.codec) KeywordRiderGrant.permanents
  pure
    KeywordRiderGrant.MkKeywordRiderGrant
      { KeywordRiderGrant.abilities = abilities,
        KeywordRiderGrant.relaxes = relaxes,
        KeywordRiderGrant.permanents = permanents
      }
