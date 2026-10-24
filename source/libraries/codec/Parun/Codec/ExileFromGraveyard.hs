{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ExileFromGraveyard where

import qualified Parun.Codec.CounterKind as CounterKind
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.HowMany as HowMany
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.PlayerScope as PlayerScope
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ExileFromGraveyard as ExileFromGraveyard
import qualified Parun.Types.HowMany as HowMany.Type
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.PlayerScope as PlayerScope.Type
import qualified Parun.Types.Quantity as Quantity.Type

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
