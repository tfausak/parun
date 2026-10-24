module Parun.Codec.ExchangeSides where

import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.ExchangeSides as ExchangeSides

-- | The wire format is unchanged by the conversion to a bundle; what it adds is
-- the schema.
codec :: Codec.Codec ExchangeSides.ExchangeSides
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "WithController" SlotName.codec ExchangeSides.WithController (\x -> case x of ExchangeSides.WithController y -> Just y; _ -> Nothing),
      Arm.payload "BetweenTargets" SlotName.codec ExchangeSides.BetweenTargets (\x -> case x of ExchangeSides.BetweenTargets y -> Just y; _ -> Nothing)
    ]

tagOf :: ExchangeSides.ExchangeSides -> String
tagOf x = case x of
  ExchangeSides.WithController {} -> "WithController"
  ExchangeSides.BetweenTargets {} -> "BetweenTargets"
