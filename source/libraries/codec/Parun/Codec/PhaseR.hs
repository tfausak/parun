{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PhaseR where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.PhasePattern as PhasePattern
import qualified Parun.Codec.PhaseRewrite as PhaseRewrite
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PhaseR as PhaseR
import qualified Parun.Types.PhaseRewrite as PhaseRewrite.Type

-- | The pattern's keys spelled beside the rewrite's, so a mandatory skip keeps
-- the bare pattern it had before skips could carry an action.
codec :: (Eq effect, Typeable.Typeable effect) => Codec.Codec effect -> Codec.Codec (PhaseR.PhaseR effect)
codec effectCodec = Fields.object $ do
  phases <- Fields.contramap PhaseR.phases PhasePattern.fields
  rewrite <- Fields.defaulted "rewrite" PhaseRewrite.Type.Skip (PhaseRewrite.codec effectCodec) PhaseR.rewrite
  pure
    PhaseR.MkPhaseR
      { PhaseR.phases = phases,
        PhaseR.rewrite = rewrite
      }
