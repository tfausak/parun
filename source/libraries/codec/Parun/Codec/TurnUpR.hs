{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.TurnUpR where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.Cost as Cost
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.TurnUpProcedure as TurnUpProcedure
import qualified Parun.Codec.TurnUpRewrite as TurnUpRewrite
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.TurnUpR as TurnUpR

-- | A bare object keyed by the record's field names, replacing the two-element
-- array this payload used to be (#1464).
--
-- `requiring` and `paying` are engine-baked -- Parun.Types.TurnUpR says why -- so
-- each defaults to Nothing and no card file writes either, the posture
-- Parun.Codec.PhasePattern's whosePhase takes.
codec ::
  (Typeable.Typeable ability, Eq ability, Typeable.Typeable effect, Eq effect) =>
  Codec.Codec ability ->
  Codec.Codec effect ->
  Codec.Codec (TurnUpR.TurnUpR ability effect)
codec abilityCodec effectCodec = Fields.object $ do
  matching <- Fields.required "matching" (Filter.codec Keyword.codec) TurnUpR.matching
  requiring <- Fields.defaulted "requiring" Nothing (Common.maybe TurnUpProcedure.codec) TurnUpR.requiring
  paying <- Fields.defaulted "paying" Nothing (Common.maybe (Cost.codec Keyword.codec)) TurnUpR.paying
  rewrite <- Fields.required "rewrite" (TurnUpRewrite.codec abilityCodec effectCodec) TurnUpR.rewrite
  pure
    TurnUpR.MkTurnUpR
      { TurnUpR.matching = matching,
        TurnUpR.requiring = requiring,
        TurnUpR.paying = paying,
        TurnUpR.rewrite = rewrite
      }
