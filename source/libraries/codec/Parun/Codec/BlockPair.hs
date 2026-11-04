{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.BlockPair where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.BlockPair as BlockPair

-- | A bare object keyed by the record's field names, both required.
codec :: Codec.Codec BlockPair.BlockPair
codec = Fields.object $ do
  blocker <- Fields.required "blocker" (Filter.codec Keyword.codec) BlockPair.blocker
  attacker <- Fields.required "attacker" (Filter.codec Keyword.codec) BlockPair.attacker
  pure BlockPair.MkBlockPair {BlockPair.blocker = blocker, BlockPair.attacker = attacker}
