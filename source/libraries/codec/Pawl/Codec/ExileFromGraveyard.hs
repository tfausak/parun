{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.ExileFromGraveyard where

import qualified Pawl.Codec.CounterKind as CounterKind
import qualified Pawl.Codec.Filter as Filter
import qualified Pawl.Codec.HowMany as HowMany
import qualified Pawl.Codec.Keyword as Keyword
import qualified Pawl.Codec.PlayerScope as PlayerScope
import qualified Pawl.Codec.Quantity as Quantity
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.ExileFromGraveyard as ExileFromGraveyard
import qualified Pawl.Types.HowMany as HowMany.Type
import qualified Pawl.Types.PlayerRelation as PlayerRelation
import qualified Pawl.Types.PlayerScope as PlayerScope.Type
import qualified Pawl.Types.Quantity as Quantity.Type

-- | A bare object keyed by the record's field names. `players` defaults to
-- "your graveyard", `count` to the printed singular, Living Lore's reading, and
-- the rest to exiling with no fallback and buying nothing.
codec :: Codec.Codec ExileFromGraveyard.ExileFromGraveyard
codec = Fields.object $ do
  count <- Fields.defaulted "count" HowMany.Type.one HowMany.codec ExileFromGraveyard.count
  each <- Fields.defaulted "each" (Quantity.Type.Literal 1) Quantity.codec ExileFromGraveyard.each
  filter_ <- Fields.required "filter" (Filter.codec Keyword.codec) ExileFromGraveyard.filter
  kinds <- Fields.defaulted "kinds" [] (Common.list (CounterKind.codec Keyword.codec)) ExileFromGraveyard.kinds
  orGraveyard <- Fields.defaulted "orGraveyard" False Common.boolean ExileFromGraveyard.orGraveyard
  players <- Fields.defaulted "players" (PlayerScope.Type.Related PlayerRelation.You) PlayerScope.codec ExileFromGraveyard.players
  pure
    ExileFromGraveyard.MkExileFromGraveyard
      { ExileFromGraveyard.count = count,
        ExileFromGraveyard.each = each,
        ExileFromGraveyard.filter = filter_,
        ExileFromGraveyard.kinds = kinds,
        ExileFromGraveyard.orGraveyard = orGraveyard,
        ExileFromGraveyard.players = players
      }
