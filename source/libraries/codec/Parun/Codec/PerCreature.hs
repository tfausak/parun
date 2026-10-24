module Parun.Codec.PerCreature where

import qualified Parun.Codec.Cost as Cost
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.PerCreature as PerCreature

-- | Tagged rather than a bare cost with a fallback, so a card says which kind of
-- share it prints: {2} and {X} are not two spellings of one thing.
codec :: Codec.Codec PerCreature.PerCreature
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "Fixed" (Cost.codec Keyword.codec) PerCreature.Fixed (\x -> case x of PerCreature.Fixed y -> Just y; _ -> Nothing),
      Arm.payload "Counted" Quantity.codec PerCreature.Counted (\x -> case x of PerCreature.Counted y -> Just y; _ -> Nothing)
    ]

tagOf :: PerCreature.PerCreature -> String
tagOf x = case x of
  PerCreature.Fixed {} -> "Fixed"
  PerCreature.Counted {} -> "Counted"
