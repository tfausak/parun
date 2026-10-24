{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.BlockersAre where

import qualified Parun.Codec.Reference as Reference
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.BlockersAre as BlockersAre

-- | @"blockers": null@ is an unblocked attacker, and @[]@ one blocked by nothing.
codec :: Codec.Codec BlockersAre.BlockersAre
codec = Fields.object $ do
  attacker <- Fields.required "attacker" Reference.codec BlockersAre.attacker
  blockers <- Fields.required "blockers" (Common.maybe (Common.set Reference.codec)) BlockersAre.blockers
  pure BlockersAre.MkBlockersAre {BlockersAre.attacker = attacker, BlockersAre.blockers = blockers}
