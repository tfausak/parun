{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.AimedAt where

import qualified Parun.Codec.AimedPlayers as AimedPlayers
import qualified Parun.Codec.AttackTargetKind as AttackTargetKind
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.AimedAt as AimedAt

-- | Parun.Codec.CantAttackPlayer's two aimed-at keys, and "kinds" required for
-- that codec's reason: which of CR 506.3's three things a printing names is the
-- sentence itself.
codec :: Codec.Codec AimedAt.AimedAt
codec = Fields.object $ do
  defenders <- Fields.required "defenders" AimedPlayers.codec AimedAt.defenders
  kinds <- Fields.required "kinds" (Common.set AttackTargetKind.codec) AimedAt.kinds
  pure
    AimedAt.MkAimedAt
      { AimedAt.defenders = defenders,
        AimedAt.kinds = kinds
      }
