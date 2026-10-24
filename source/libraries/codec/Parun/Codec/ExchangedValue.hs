module Parun.Codec.ExchangedValue where

import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.ExchangedValue as ExchangedValue

codec :: Codec.Codec ExchangedValue.ExchangedValue
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "LifeTotal" PlayerRef.codec ExchangedValue.LifeTotal (\x -> case x of ExchangedValue.LifeTotal y -> Just y; _ -> Nothing),
      Arm.payload "Power" ObjectRef.codec ExchangedValue.Power (\x -> case x of ExchangedValue.Power y -> Just y; _ -> Nothing),
      Arm.payload "Toughness" ObjectRef.codec ExchangedValue.Toughness (\x -> case x of ExchangedValue.Toughness y -> Just y; _ -> Nothing)
    ]

tagOf :: ExchangedValue.ExchangedValue -> String
tagOf x = case x of
  ExchangedValue.LifeTotal {} -> "LifeTotal"
  ExchangedValue.Power {} -> "Power"
  ExchangedValue.Toughness {} -> "Toughness"
