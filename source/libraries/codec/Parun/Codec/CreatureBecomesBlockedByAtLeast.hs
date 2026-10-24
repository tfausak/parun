{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.CreatureBecomesBlockedByAtLeast where

import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.CreatureBecomesBlockedByAtLeast as CreatureBecomesBlockedByAtLeast

-- | A bare object keyed by the record's field names, as
-- Parun.Codec.PlayerDrawsNthCard is.
codec :: Codec.Codec CreatureBecomesBlockedByAtLeast.CreatureBecomesBlockedByAtLeast
codec = Fields.object $ do
  attacked <- Fields.required "attacked" PlayerRelation.codec CreatureBecomesBlockedByAtLeast.attacked
  blockers <- Fields.required "blockers" Common.natural CreatureBecomesBlockedByAtLeast.blockers
  pure
    CreatureBecomesBlockedByAtLeast.MkCreatureBecomesBlockedByAtLeast
      { CreatureBecomesBlockedByAtLeast.attacked = attacked,
        CreatureBecomesBlockedByAtLeast.blockers = blockers
      }
