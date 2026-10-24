{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.AlternativeActivationCost where

import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.KeywordDesignator as KeywordDesignator
import qualified Parun.Codec.ManaCost as ManaCost
import qualified Parun.Codec.TurnScope as TurnScope
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.AlternativeActivationCost as AlternativeActivationCost

-- | A bare object keyed by the record's field names. The tag that picks it is
-- written by Parun.Codec.PlayerEffect's AlternativeActivationCost arm.
-- `onlyFirst` is defaulted to Nothing, every matching activation.
codec :: Codec.Codec AlternativeActivationCost.AlternativeActivationCost
codec = Fields.object $ do
  grantedBy <- Fields.required "grantedBy" (KeywordDesignator.codec Keyword.codec) AlternativeActivationCost.grantedBy
  onlyFirst <- Fields.defaulted "onlyFirst" Nothing (Common.maybe TurnScope.codec) AlternativeActivationCost.onlyFirst
  cost <- Fields.required "cost" ManaCost.codec AlternativeActivationCost.cost
  pure
    AlternativeActivationCost.MkAlternativeActivationCost
      { AlternativeActivationCost.grantedBy = grantedBy,
        AlternativeActivationCost.onlyFirst = onlyFirst,
        AlternativeActivationCost.cost = cost
      }
