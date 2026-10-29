module Parun.Codec.CastRepetition where

import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.CastRepetition as CastRepetition

-- | Tagged rather than an enum, since one arm carries a quantity.
codec :: Codec.Codec CastRepetition.CastRepetition
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "Once" CastRepetition.Once,
      Arm.nullary "AnyNumber" CastRepetition.AnyNumber,
      Arm.payload "WithinTotalManaValue" Quantity.codec CastRepetition.WithinTotalManaValue (\x -> case x of CastRepetition.WithinTotalManaValue y -> Just y; _ -> Nothing),
      Arm.payload "UpTo" Quantity.codec CastRepetition.UpTo (\x -> case x of CastRepetition.UpTo y -> Just y; _ -> Nothing)
    ]

tagOf :: CastRepetition.CastRepetition -> String
tagOf x = case x of
  CastRepetition.Once {} -> "Once"
  CastRepetition.AnyNumber {} -> "AnyNumber"
  CastRepetition.WithinTotalManaValue {} -> "WithinTotalManaValue"
  CastRepetition.UpTo {} -> "UpTo"
