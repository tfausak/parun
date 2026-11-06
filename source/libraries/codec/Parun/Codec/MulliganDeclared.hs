{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.MulliganDeclared where

import qualified Parun.Codec.MulliganDecision as MulliganDecision
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.MulliganDeclared as MulliganDeclared

-- | A bare object keyed by the record's field names. Runtime-only.
codec :: Codec.Codec MulliganDeclared.MulliganDeclared
codec = Fields.object $ do
  player <- Fields.required "player" PlayerId.codec MulliganDeclared.player
  decision <- Fields.required "decision" MulliganDecision.codec MulliganDeclared.decision
  bottomCount <- Fields.required "bottomCount" Common.natural MulliganDeclared.bottomCount
  pure
    MulliganDeclared.MkMulliganDeclared
      { MulliganDeclared.player = player,
        MulliganDeclared.decision = decision,
        MulliganDeclared.bottomCount = bottomCount
      }
