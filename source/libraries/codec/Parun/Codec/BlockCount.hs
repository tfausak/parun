{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.BlockCount where

import qualified Numeric.Natural as Natural
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.BlockCount as BlockCount
import qualified Parun.Types.Filter as FilterType
import qualified Parun.Types.Keyword as KeywordType

codec :: Codec.Codec BlockCount.BlockCount
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "Once" BlockCount.Once,
      Arm.payload "EachCreature" (Filter.codec Keyword.codec) BlockCount.EachCreature (\x -> case x of BlockCount.EachCreature y -> Just y; _ -> Nothing),
      Arm.payload "AtLeast" floorCodec (uncurry BlockCount.AtLeast) (\x -> case x of BlockCount.AtLeast n f -> Just (n, f); _ -> Nothing)
    ]

-- | AtLeast's two fields as an object; "others" defaults to any creature.
floorCodec :: Codec.Codec (Natural.Natural, FilterType.Filter KeywordType.Keyword)
floorCodec = Fields.object $ do
  floor_ <- Fields.required "floor" Common.natural fst
  others <- Fields.defaulted "others" (FilterType.And []) (Filter.codec Keyword.codec) snd
  pure (floor_, others)

tagOf :: BlockCount.BlockCount -> String
tagOf x = case x of
  BlockCount.Once {} -> "Once"
  BlockCount.EachCreature {} -> "EachCreature"
  BlockCount.AtLeast {} -> "AtLeast"
