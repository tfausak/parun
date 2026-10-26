module Parun.Codec.Gift where

import qualified Parun.Codec.Subtype as Subtype
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.Gift as Gift

codec :: Codec.Codec Gift.Gift
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "Card" Gift.Card,
      Arm.nullary "Food" Gift.Food,
      Arm.payload "TappedFish" Subtype.codec Gift.TappedFish (\x -> case x of Gift.TappedFish y -> Just y; _ -> Nothing),
      Arm.payload "Octopus" Subtype.codec Gift.Octopus (\x -> case x of Gift.Octopus y -> Just y; _ -> Nothing),
      Arm.nullary "Treasure" Gift.Treasure
    ]

tagOf :: Gift.Gift -> String
tagOf x = case x of
  Gift.Card -> "Card"
  Gift.Food -> "Food"
  Gift.TappedFish {} -> "TappedFish"
  Gift.Octopus {} -> "Octopus"
  Gift.Treasure -> "Treasure"
