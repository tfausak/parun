module Pawl.Codec.ManaSpecification where

import qualified Pawl.Codec.Color as Color
import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.Types.ManaSpecification as ManaSpecification

codec :: Codec.Codec ManaSpecification.ManaSpecification
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "AnyMana" ManaSpecification.AnyMana,
      Arm.nullary "ChosenColor" ManaSpecification.ChosenColor,
      Arm.payload "OfColor" Color.codec ManaSpecification.OfColor (\x -> case x of ManaSpecification.OfColor y -> Just y; _ -> Nothing)
    ]

tagOf :: ManaSpecification.ManaSpecification -> String
tagOf x = case x of
  ManaSpecification.AnyMana {} -> "AnyMana"
  ManaSpecification.ChosenColor {} -> "ChosenColor"
  ManaSpecification.OfColor {} -> "OfColor"
