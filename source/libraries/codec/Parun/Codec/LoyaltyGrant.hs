{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.LoyaltyGrant where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.LoyaltyClause as LoyaltyClause
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.LoyaltyGrant as LoyaltyGrant

-- | A bare object keyed by the record's field names, as every other
-- Parun.Types.PlayerEffect payload is (#1464).
codec :: Codec.Codec LoyaltyGrant.LoyaltyGrant
codec = Fields.object $ do
  relaxes <- Fields.required "relaxes" LoyaltyClause.codec LoyaltyGrant.relaxes
  permanents <- Fields.required "permanents" (Filter.codec Keyword.codec) LoyaltyGrant.permanents
  pure LoyaltyGrant.MkLoyaltyGrant {LoyaltyGrant.relaxes = relaxes, LoyaltyGrant.permanents = permanents}
