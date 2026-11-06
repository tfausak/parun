{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.DamageTally where

import qualified Parun.Codec.DealtDamage as DealtDamage
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.Codec.WhichTurn as WhichTurn
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.DamageTally as DamageTally
import qualified Parun.Types.WhichTurn as WhichTurn.Type

-- | A bare object holding Parun.Codec.DealtDamage's keys beside `turn`, which is
-- 'Fields.defaulted', so a card asking about this turn writes only those.
codec :: Codec.Codec DamageTally.DamageTally
codec = Fields.object $ do
  dealt <- Fields.contramap DamageTally.dealt (DealtDamage.fields PlayerRef.codec)
  turn <- Fields.defaulted "turn" WhichTurn.Type.ThisTurn WhichTurn.codec DamageTally.turn
  pure DamageTally.MkDamageTally {DamageTally.dealt = dealt, DamageTally.turn = turn}
