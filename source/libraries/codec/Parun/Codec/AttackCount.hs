{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.AttackCount where

import qualified Data.Text as Text
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.AttackCount as AttackCount

-- | A bare object keyed by the record's field names, both required: a
-- defaulted floor would let a card mean "one or more" by saying nothing. A zero
-- floor is refused, since it would be CR 508.3d's "attacks" spelled another way.
codec :: Codec.Codec AttackCount.AttackCount
codec =
  let check p =
        if AttackCount.floor p == 0
          then Left (Text.pack "attack trigger has a zero attackers floor")
          else Right p
   in Fields.objectWith check $ do
        floor_ <- Fields.required "floor" Common.natural AttackCount.floor
        filter_ <- Fields.required "filter" (Filter.codec Keyword.codec) AttackCount.filter
        pure AttackCount.MkAttackCount {AttackCount.floor = floor_, AttackCount.filter = filter_}
