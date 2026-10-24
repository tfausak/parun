module Parun.Codec.CostScale where

import qualified Parun.Codec.Color as Color
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.CostScale as CostScale

-- | Tagged rather than an enum, since one arm carries a colour.
codec :: Codec.Codec CostScale.CostScale
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "Once" CostScale.Once,
      Arm.payload "PerColoredSymbol" Color.codec CostScale.PerColoredSymbol (\x -> case x of CostScale.PerColoredSymbol y -> Just y; _ -> Nothing)
    ]

tagOf :: CostScale.CostScale -> String
tagOf x = case x of
  CostScale.Once {} -> "Once"
  CostScale.PerColoredSymbol {} -> "PerColoredSymbol"
