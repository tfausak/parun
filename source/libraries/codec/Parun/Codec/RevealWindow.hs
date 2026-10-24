module Parun.Codec.RevealWindow where

import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.RevealWindow as RevealWindow

codec :: Codec.Codec RevealWindow.RevealWindow
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "WhileOnStack" ObjectId.codec RevealWindow.WhileOnStack (\x -> case x of RevealWindow.WhileOnStack y -> Just y; _ -> Nothing),
      Arm.nullary "UntilPriority" RevealWindow.UntilPriority,
      Arm.nullary "UntilFirstTurn" RevealWindow.UntilFirstTurn,
      Arm.payload "DuringUpkeep" Common.natural RevealWindow.DuringUpkeep (\x -> case x of RevealWindow.DuringUpkeep y -> Just y; _ -> Nothing)
    ]

tagOf :: RevealWindow.RevealWindow -> String
tagOf x = case x of
  RevealWindow.WhileOnStack {} -> "WhileOnStack"
  RevealWindow.UntilPriority {} -> "UntilPriority"
  RevealWindow.UntilFirstTurn {} -> "UntilFirstTurn"
  RevealWindow.DuringUpkeep {} -> "DuringUpkeep"
