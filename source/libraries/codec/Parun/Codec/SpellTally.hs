{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.SpellTally where

import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.Codec.WhichTurn as WhichTurn
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.SpellTally as SpellTally
import qualified Parun.Types.WhichTurn as WhichTurn.Type

-- | A bare object keyed by the record's field names. `turn` is
-- 'Fields.defaulted', so a card asking about this turn writes only `player`.
codec :: Codec.Codec SpellTally.SpellTally
codec = Fields.object $ do
  player <- Fields.required "player" PlayerRef.codec SpellTally.player
  turn <- Fields.defaulted "turn" WhichTurn.Type.ThisTurn WhichTurn.codec SpellTally.turn
  pure SpellTally.MkSpellTally {SpellTally.player = player, SpellTally.turn = turn}
