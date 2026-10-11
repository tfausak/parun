{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.ExileFromGraveyard where

import qualified Pawl.Codec.Filter as Filter
import qualified Pawl.Codec.HowMany as HowMany
import qualified Pawl.Codec.Keyword as Keyword
import qualified Pawl.Codec.PlayerScope as PlayerScope
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.ExileFromGraveyard as ExileFromGraveyard
import qualified Pawl.Types.HowMany as HowMany.Type
import qualified Pawl.Types.PlayerRelation as PlayerRelation
import qualified Pawl.Types.PlayerScope as PlayerScope.Type

-- | A bare object keyed by the record's field names. `players` defaults to
-- "your graveyard" and `count` to the printed singular, Living Lore's reading.
codec :: Codec.Codec ExileFromGraveyard.ExileFromGraveyard
codec = Fields.object $ do
  count <- Fields.defaulted "count" HowMany.Type.one HowMany.codec ExileFromGraveyard.count
  filter_ <- Fields.required "filter" (Filter.codec Keyword.codec) ExileFromGraveyard.filter
  players <- Fields.defaulted "players" (PlayerScope.Type.Related PlayerRelation.You) PlayerScope.codec ExileFromGraveyard.players
  pure
    ExileFromGraveyard.MkExileFromGraveyard
      { ExileFromGraveyard.count = count,
        ExileFromGraveyard.filter = filter_,
        ExileFromGraveyard.players = players
      }
