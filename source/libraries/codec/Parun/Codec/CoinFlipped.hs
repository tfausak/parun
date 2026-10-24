{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.CoinFlipped where

import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.CoinFlipped as CoinFlipped

-- | A bare object keyed by the record's field names, Parun.Codec.Mentored's
-- shape. Runtime-only: GameEvent serialises transcripts, never card data.
--
-- "flipper" is REQUIRED and "won" is not, which is CR 705.2's own split: the
-- rule settles a win or a loss for the flips its second sentence describes, and
-- explicitly settles neither for the ones its first sentence describes. An
-- absent key is that flip -- not a default standing in for an answer the rule
-- gives.
codec :: Codec.Codec CoinFlipped.CoinFlipped
codec = Fields.object $ do
  flipper <- Fields.required "flipper" PlayerId.codec CoinFlipped.flipper
  won <- Fields.defaulted "won" Nothing (Common.maybe Common.boolean) CoinFlipped.won
  pure
    CoinFlipped.MkCoinFlipped
      { CoinFlipped.flipper = flipper,
        CoinFlipped.won = won
      }
