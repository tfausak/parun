{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.CompletedDungeon where

import qualified Parun.Codec.CardName as CardName
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.CompletedDungeon as CompletedDungeon

-- | A bare object keyed by the record's field names, Parun.Codec.PlayerCounterTally's
-- shape. The tag that picks it is Parun.Codec.Quantity's "CompletedDungeon".
codec :: Codec.Codec CompletedDungeon.CompletedDungeon
codec = Fields.object $ do
  player <- Fields.required "player" PlayerRef.codec CompletedDungeon.player
  dungeon <- Fields.required "dungeon" CardName.codec CompletedDungeon.dungeon
  pure CompletedDungeon.MkCompletedDungeon {CompletedDungeon.player = player, CompletedDungeon.dungeon = dungeon}
