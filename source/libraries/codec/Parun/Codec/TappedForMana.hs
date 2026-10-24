{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.TappedForMana where

import qualified Parun.Codec.ManaType as ManaType
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.TappedForMana as TappedForMana

-- | A bare object keyed by the record's field names. Both keys required: this
-- is a log entry rather than card data, written by one producer that always
-- knows both halves (Parun.Engine.Cost.applyManaTriggers), so an absent `mana`
-- would only ever be a truncated document.
codec :: Codec.Codec TappedForMana.TappedForMana
codec = Fields.object $ do
  permanent <- Fields.required "permanent" ObjectId.codec TappedForMana.permanent
  mana <- Fields.required "mana" (Common.set ManaType.codec) TappedForMana.mana
  player <- Fields.required "player" PlayerId.codec TappedForMana.player
  pure TappedForMana.MkTappedForMana {TappedForMana.permanent = permanent, TappedForMana.mana = mana, TappedForMana.player = player}
