{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.BlockTrigger where

import qualified Parun.Codec.BlockCount as BlockCount
import qualified Parun.Codec.BlockRole as BlockRole
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.BlockCount as BlockCountType
import qualified Parun.Types.BlockTrigger as BlockTrigger
import qualified Parun.Types.Filter as FilterType

-- | A bare object keyed by the record's field names. The source's own creature
-- and Once write no key.
codec :: Codec.Codec BlockTrigger.BlockTrigger
codec = Fields.object $ do
  role <- Fields.required "role" BlockRole.codec BlockTrigger.role
  creature <- Fields.defaulted "creature" FilterType.IsSource (Filter.codec Keyword.codec) BlockTrigger.creature
  count <- Fields.defaulted "count" BlockCountType.Once BlockCount.codec BlockTrigger.count
  pure
    BlockTrigger.MkBlockTrigger
      { BlockTrigger.role = role,
        BlockTrigger.creature = creature,
        BlockTrigger.count = count
      }
