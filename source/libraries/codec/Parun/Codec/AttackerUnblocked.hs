{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.AttackerUnblocked where

import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.AttackerUnblocked as AttackerUnblocked

-- | A bare object keyed by the record's field names. Runtime-only: GameEvent
-- serialises transcripts, never card data.
codec :: Codec.Codec AttackerUnblocked.AttackerUnblocked
codec = Fields.object $ do
  attacker <- Fields.required "attacker" ObjectId.codec AttackerUnblocked.attacker
  defender <- Fields.required "defender" PlayerId.codec AttackerUnblocked.defender
  pure
    AttackerUnblocked.MkAttackerUnblocked
      { AttackerUnblocked.attacker = attacker,
        AttackerUnblocked.defender = defender
      }
