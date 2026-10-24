{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.AppliedReduction where

import qualified Parun.Codec.ManaCost as ManaCost
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.AppliedReduction as AppliedReduction

-- | A bare object keyed by the record's field names. @atLeast@ and
-- @coloredOnly@ are DEFAULTED to the rules' own answers -- no floor past CR
-- 601.2f's {0}, and CR 118.7b-d's spill -- so only a card printing Heartstone's
-- or Edgewalker's sentence writes either.
codec :: Codec.Codec AppliedReduction.AppliedReduction
codec = Fields.object $ do
  amount <- Fields.required "amount" ManaCost.codec AppliedReduction.amount
  atLeast <- Fields.defaulted "atLeast" 0 Common.natural AppliedReduction.atLeast
  coloredOnly <- Fields.defaulted "coloredOnly" False Common.boolean AppliedReduction.coloredOnly
  pure AppliedReduction.MkAppliedReduction {AppliedReduction.amount = amount, AppliedReduction.atLeast = atLeast, AppliedReduction.coloredOnly = coloredOnly}
