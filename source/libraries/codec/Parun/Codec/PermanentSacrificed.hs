{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PermanentSacrificed where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PermanentSacrificed as PermanentSacrificed

-- | A bare object keyed by the record's field names, as
-- Parun.Codec.PlayerAttacksWith is. Both keys are required: the unrestricted
-- printed wording spells itself out as AnyPlayer and the trivial Filter rather
-- than leaving either out.
codec :: Codec.Codec PermanentSacrificed.PermanentSacrificed
codec = Fields.object $ do
  player <- Fields.required "player" PlayerRelation.codec PermanentSacrificed.player
  filter_ <- Fields.required "filter" (Filter.codec Keyword.codec) PermanentSacrificed.filter
  pure PermanentSacrificed.MkPermanentSacrificed {PermanentSacrificed.player = player, PermanentSacrificed.filter = filter_}
