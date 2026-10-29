{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.LifeTally where

import qualified Parun.Codec.LifeDirection as LifeDirection
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.Codec.WhichTurn as WhichTurn
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.LifeTally as LifeTally
import qualified Parun.Types.WhichTurn as WhichTurn.Type

-- | A bare object keyed by the record's field names. `turn` is
-- 'Fields.defaulted', so a card asking about this turn writes only `player` and
-- `direction`.
codec :: Codec.Codec LifeTally.LifeTally
codec = Fields.object $ do
  player <- Fields.required "player" PlayerRef.codec LifeTally.player
  direction <- Fields.required "direction" LifeDirection.codec LifeTally.direction
  turn <- Fields.defaulted "turn" WhichTurn.Type.ThisTurn WhichTurn.codec LifeTally.turn
  pure LifeTally.MkLifeTally {LifeTally.player = player, LifeTally.direction = direction, LifeTally.turn = turn}
